// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./ERC721MMCLibrary.sol";

error IncorrectOwner();
error NonexistentToken();
error QueryForZeroAddress();
error CallerNotOwnerNorApproved();

error MintZeroQuantity();
error MintToZeroAddress();
error MintExceedsMaxSupply();
error MintExceedsMaxPerWallet();

error TransferFromIncorrectOwner();
error TransferToNonERC721Receiver();
error TransferToZeroAddress();

error ApprovalToCaller();
error ApproveToCurrentOwner();

error TokenIdUnstaked();
error ExceedsStakingLimit();

abstract contract ERC721MMC {
    using UserDataOps for uint256;
    using TokenDataOps for uint256;

    event Transfer(address indexed from, address indexed to, uint256 indexed id);
    event Approval(address indexed owner, address indexed spender, uint256 indexed id);
    event ApprovalForAll(address indexed owner, address indexed operator, bool approved);

    string public name;
    string public symbol;

    mapping(uint256 => address) public getApproved;
    mapping(address => mapping(address => bool)) public isApprovedForAll;

    uint256 public totalSupply;

    uint256 immutable startingIndex;
    uint256 immutable collectionSize;
    uint256 immutable maxPerWallet;

    // note: hard limit of 255, otherwise overflows can happen
    uint256 constant stakingLimit = 100;

    mapping(uint256 => uint256) internal _tokenData;
    mapping(address => uint256) internal _userData;

    constructor(
        string memory name_,
        string memory symbol_,
        uint256 startingIndex_,
        uint256 collectionSize_,
        uint256 maxPerWallet_
    ) {
        name = name_;
        symbol = symbol_;
        collectionSize = collectionSize_;
        maxPerWallet = maxPerWallet_;
        startingIndex = startingIndex_;
    }

    /* ------------- External ------------- */

    function approve(address spender, uint256 tokenId) external {
        address owner = _tokenDataOf(tokenId).owner();

        if (msg.sender != owner && !isApprovedForAll[owner][msg.sender]) revert CallerNotOwnerNorApproved();

        getApproved[tokenId] = spender;
        emit Approval(owner, spender, tokenId);
    }

    function setApprovalForAll(address operator, bool approved) external {
        isApprovedForAll[msg.sender][operator] = approved;
        emit ApprovalForAll(msg.sender, operator, approved);
    }

    function transferFrom(
        address from,
        address to,
        uint256 tokenId
    ) public {
        // make sure no one is misled by token transfer events
        if (to == address(this)) {
            uint256 userData = _claimReward();
            _userData[msg.sender] = _stake(msg.sender, tokenId, userData);
        } else {
            uint256 tokenData = _tokenDataOf(tokenId);

            if (tokenData.owner() != from) revert TransferFromIncorrectOwner();

            bool isApprovedOrOwner = (msg.sender == from ||
                isApprovedForAll[from][msg.sender] ||
                getApproved[tokenId] == msg.sender);

            if (!isApprovedOrOwner) revert CallerNotOwnerNorApproved();
            if (to == address(0)) revert TransferToZeroAddress();

            delete getApproved[tokenId];

            unchecked {
                _tokenData[tokenId] = _ensureTokenDataSet(tokenId + 1, tokenData)
                    .setOwner(to)
                    .setLastTransfer(block.timestamp)
                    .incrementOwnerCount();
            }

            _userData[from] = _userData[from].decreaseBalance(1);
            _userData[to] = _userData[to].increaseBalance(1);

            emit Transfer(from, to, tokenId);
        }
    }

    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId
    ) external {
        safeTransferFrom(from, to, tokenId, "");
    }

    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId,
        bytes memory data
    ) public {
        transferFrom(from, to, tokenId);
        if (
            to.code.length != 0 &&
            IERC721Receiver(to).onERC721Received(msg.sender, from, tokenId, data) !=
            IERC721Receiver(to).onERC721Received.selector
        ) revert TransferToNonERC721Receiver();
    }

    function stake(uint256[] calldata tokenIds) external payable {
        uint256 userData = _claimReward();
        for (uint256 i; i < tokenIds.length; ++i) userData = _stake(msg.sender, tokenIds[i], userData);
        _userData[msg.sender] = userData;
    }

    function unstake(uint256[] calldata tokenIds) external payable {
        uint256 userData = _claimReward();
        for (uint256 i; i < tokenIds.length; ++i) userData = _unstake(msg.sender, tokenIds[i], userData);
        _userData[msg.sender] = userData;
    }

    function claimReward() external payable {
        _userData[msg.sender] = _claimReward();
    }

    /* ------------- Private ------------- */

    function _stake(
        address from,
        uint256 tokenId,
        uint256 userData
    ) private returns (uint256) {
        uint256 numStaked_ = userData.numStaked();

        uint256 tokenData = _tokenDataOf(tokenId);
        address owner = tokenData.owner();

        if (numStaked_ >= stakingLimit) revert ExceedsStakingLimit();
        if (owner != from) revert IncorrectOwner();

        delete getApproved[tokenId];

        // hook, used for reading DNA, updating role balances,
        (uint256 userDataX, uint256 tokenDataX) = _beforeStakeDataTransform(tokenId, userData, tokenData);
        (userData, tokenData) = applySafeDataTransform(userData, tokenData, userDataX, tokenDataX);

        tokenData = tokenData.setstaked();
        userData = userData.decreaseBalance(1).increaseNumStaked(1).setLastClaimed(block.timestamp);

        if (numStaked_ == 0) userData = userData.setStakeStart(block.timestamp);

        _tokenData[tokenId] = tokenData;

        emit Transfer(from, address(this), tokenId);

        return userData;
    }

    function _unstake(
        address to,
        uint256 tokenId,
        uint256 userData
    ) private returns (uint256) {
        uint256 tokenData = _tokenDataOf(tokenId);
        address owner = tokenData.trueOwner();
        bool isStaked = tokenData.staked();

        if (owner != to) revert IncorrectOwner();
        if (!isStaked) revert TokenIdUnstaked();

        (uint256 userDataX, uint256 tokenDataX) = _beforeUnstakeDataTransform(tokenId, userData, tokenData);
        (userData, tokenData) = applySafeDataTransform(userData, tokenData, userDataX, tokenDataX);

        // if mintAndStake flag is set, we need to make sure that next tokenData is set
        // because tokenData in this case is implicit and needs to carry over
        if (tokenData.mintAndStake()) {
            unchecked {
                tokenData = _ensureTokenDataSet(tokenId + 1, tokenData).unsetMintAndStake();
            }
        }

        tokenData = tokenData.unsetstaked();
        userData = userData.increaseBalance(1).decreaseNumStaked(1).setStakeStart(block.timestamp);

        _tokenData[tokenId] = tokenData;

        emit Transfer(address(this), to, tokenId);

        return userData;
    }

    /* ------------- View ------------- */

    function tokenURI(uint256 id) public view virtual returns (string memory);

    function supportsInterface(bytes4 interfaceId) external view virtual returns (bool) {
        return
            interfaceId == 0x01ffc9a7 || // ERC165 Interface ID for ERC165
            interfaceId == 0x80ac58cd || // ERC165 Interface ID for ERC721
            interfaceId == 0x5b5e139f; // ERC165 Interface ID for ERC721Metadata
    }

    function balanceOf(address owner) public view returns (uint256) {
        if (owner == address(0)) revert QueryForZeroAddress();
        return _userData[owner].balance();
    }

    function numMinted(address user) public view returns (uint256) {
        return _userData[user].numMinted();
    }

    function ownerOf(uint256 tokenId) public view returns (address) {
        return _tokenDataOf(tokenId).owner();
    }

    function trueOwnerOf(uint256 tokenId) public view returns (address) {
        return _tokenDataOf(tokenId).trueOwner();
    }

    function numStaked(address user) public view returns (uint256) {
        return _userData[user].numStaked();
    }

    function numOwned(address user) public view returns (uint256) {
        uint256 userData = _userData[user];
        return userData.balance() + userData.numStaked();
    }

    function pendingReward(address user) public view returns (uint256) {
        return _pendingReward(user, _userData[user]);
    }

    // O(N) read-only functions

    function tokenIdsOf(address user) external view returns (uint256[] memory) {
        return tokenIdsOf(user, 0);
    }

    function stakedTokenIdsOf(address user) external view returns (uint256[] memory) {
        return tokenIdsOf(user, 1);
    }

    function allTokenIdsOf(address user) external view returns (uint256[] memory) {
        return tokenIdsOf(user, 2);
    }

    function tokenIdsOf(address user, uint256 type_) private view returns (uint256[] memory) {
        unchecked {
            uint256 balance = type_ == 0 ? balanceOf(user) : type_ == 1 ? numStaked(user) : numOwned(user);

            uint256[] memory ids = new uint256[](balance);

            if (balance == 0) return ids;

            uint256 count;
            for (uint256 i = startingIndex; i < totalSupply + startingIndex; ++i) {
                uint256 tokenData = _tokenDataOf(i);
                if (user == tokenData.trueOwner()) {
                    bool staked = tokenData.staked();
                    if ((type_ == 0 && !staked) || (type_ == 1 && staked) || type_ == 2) {
                        ids[count++] = i;
                        if (balance == count) return ids;
                    }
                }
            }

            return ids;
        }
    }

    function totalNumStaked() external view returns (uint256) {
        unchecked {
            uint256 count;
            for (uint256 i = startingIndex; i < startingIndex + totalSupply; ++i) {
                if (_tokenDataOf(i).staked()) ++count;
            }
            return count;
        }
    }

    /* ------------- Internal ------------- */

    function _exists(uint256 tokenId) internal view returns (bool) {
        return startingIndex <= tokenId && tokenId < startingIndex + totalSupply;
    }

    function _tokenDataOf(uint256 tokenId) public view returns (uint256) {
        if (!_exists(tokenId)) revert NonexistentToken();

        for (uint256 curr = tokenId; ; curr--) {
            uint256 tokenData = _tokenData[curr];
            if (tokenData != 0) return (curr == tokenId) ? tokenData : tokenData.copy();
        }

        // unreachable
        return 0;
    }

    function _ensureTokenDataSet(uint256 tokenId, uint256 tokenData) private returns (uint256) {
        if (!tokenData.nextTokenDataSet() && _tokenData[tokenId] == 0 && _exists(tokenId))
            _tokenData[tokenId] = tokenData.copy(); // make sure to not pass any token specific data in
        return tokenData.flagNextTokenDataSet();
    }

    function _mintAndStake(
        address to,
        uint256 quantity,
        bool stake_
    ) internal {
        unchecked {
            if (to == address(0)) revert MintToZeroAddress();
            if (quantity == 0) revert MintZeroQuantity();

            uint256 supply = totalSupply;
            uint256 startTokenId = startingIndex + supply;

            uint256 userData = _userData[to];
            uint256 numMinted_ = userData.numMinted();

            if (supply + quantity > collectionSize) revert MintExceedsMaxSupply();
            if (numMinted_ + quantity > maxPerWallet && to == msg.sender && address(this).code.length != 0)
                revert MintExceedsMaxPerWallet();

            // // don't update for airdrops
            // if (to == msg.sender) userData = userData.increaseNumMinted(quantity);
            userData = userData.increaseNumMinted(quantity);

            uint256 tokenData = TokenDataOps.newTokenData(to, block.timestamp, stake_);

            // don't have to care about next token data if only minting one
            // could optimize to implicitly flag last token id of batch
            if (quantity == 1) tokenData = tokenData.flagNextTokenDataSet();

            if (stake_) {
                uint256 numStaked_ = userData.numStaked();

                userData = claimReward(userData);
                userData = userData.increaseNumStaked(quantity);

                if (numStaked_ + quantity > stakingLimit) revert ExceedsStakingLimit();
                if (numStaked_ == 0) userData = userData.setStakeStart(block.timestamp);

                uint256 tokenId;
                for (uint256 i; i < quantity; ++i) {
                    tokenId = startTokenId + i;

                    (userData, tokenData) = _beforeStakeDataTransform(tokenId, userData, tokenData);

                    emit Transfer(address(0), to, tokenId);
                    emit Transfer(to, address(this), tokenId);
                }
            } else {
                userData = userData.increaseBalance(quantity);
                for (uint256 i; i < quantity; ++i) emit Transfer(address(0), to, startTokenId + i);
            }

            _userData[to] = userData;
            _tokenData[startTokenId] = tokenData;

            totalSupply += quantity;
        }
    }

    function _claimReward() internal returns (uint256) {
        uint256 userData = _userData[msg.sender];
        return claimReward(userData);
    }

    function claimReward(uint256 userData) internal virtual returns (uint256) {
        uint256 reward = _pendingReward(msg.sender, userData);

        userData = userData.setLastClaimed(block.timestamp);

        _payoutReward(msg.sender, reward);

        return userData;
    }

    /* ------------- Virtual (hooks) ------------- */

    function _beforeStakeDataTransform(
        uint256, /* tokenId */
        uint256 userData,
        uint256 tokenData
    ) internal view virtual returns (uint256, uint256) {
        return (userData, tokenData);
    }

    function _beforeUnstakeDataTransform(
        uint256, /* tokenId */
        uint256 userData,
        uint256 tokenData
    ) internal view virtual returns (uint256, uint256) {
        return (userData, tokenData);
    }

    function _pendingReward(address user, uint256 userData) internal view virtual returns (uint256);

    function _payoutReward(address user, uint256 reward) internal virtual;
}

interface IERC721Receiver {
    function onERC721Received(
        address operator,
        address from,
        uint256 id,
        bytes calldata data
    ) external returns (bytes4);
}
