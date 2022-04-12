// SPDX-License-Identifier: AGPL-3.0-only
pragma solidity ^0.8.0;

error IncorrectOwner();
error NonexistentToken();
error CallerNotOwnerNorApproved();

error MintZeroQuantity();
error MintToZeroAddress();
error MintExceedsMaxSupply();
error MintExceedsMaxPerWallet();

error TransferToZeroAddress();
error TransferFromIncorrectOwner();
error TransferToNonERC721Receiver();

error TokenIdUnstaked();
error ExceedsStakingLimit();

abstract contract ERC721M {
    event Transfer(address indexed from, address indexed to, uint256 indexed id);
    event Approval(address indexed owner, address indexed spender, uint256 indexed id);
    event ApprovalForAll(address indexed owner, address indexed operator, bool approved);

    struct TokenData {
        address owner;
        uint40 lastTransfer;
        uint24 ownerCount;
        bool staked;
        bool mintAndStaked;
        bool nextTokenDataSet;
    }

    struct UserData {
        uint40 balance;
        uint40 numMinted;
        uint40 stakeStart;
        uint40 lastClaimed;
        uint40 numStaked;
    }

    uint256 public immutable startingIndex;
    uint256 public immutable collectionSize;
    uint256 public immutable maxPerWallet;

    // note: hard limit of 255, otherwise overflows can happen
    uint256 constant stakingLimit = 255;

    uint256 private _currentIndex;

    string private _name;
    string private _symbol;

    mapping(uint256 => address) public getApproved;
    mapping(address => mapping(address => bool)) public isApprovedForAll;

    mapping(uint256 => TokenData) private _tokenData;
    mapping(address => UserData) private _userData;

    constructor(
        string memory name_,
        string memory symbol_,
        uint256 startingIndex_,
        uint256 collectionSize_,
        uint256 maxPerWallet_
    ) {
        _name = name_;
        _symbol = symbol_;

        startingIndex = startingIndex_;
        collectionSize = collectionSize_;
        maxPerWallet = maxPerWallet_;

        _currentIndex = startingIndex;
    }

    /* ------------- External ------------- */

    function approve(address to, uint256 tokenId) external {
        address owner = ownerOf(tokenId);

        if (msg.sender != owner && !isApprovedForAll[owner][msg.sender]) revert CallerNotOwnerNorApproved();

        getApproved[tokenId] = to;
        emit Approval(owner, to, tokenId);
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
        unchecked {
            // make sure no one is misled by token transfer events
            if (to == address(this)) {
                UserData memory userData = _claimReward();
                _userData[msg.sender] = _stake(msg.sender, tokenId, userData);
            } else {
                TokenData memory tokenData = _tokenDataOf(tokenId);

                if (tokenData.owner != from || tokenData.staked) revert TransferFromIncorrectOwner();

                bool isApprovedOrOwner = (msg.sender == from ||
                    isApprovedForAll[from][msg.sender] ||
                    getApproved[tokenId] == msg.sender);

                if (!isApprovedOrOwner) revert CallerNotOwnerNorApproved();
                if (to == address(0)) revert TransferToZeroAddress();

                delete getApproved[tokenId];

                --_userData[from].balance;
                ++_userData[to].balance;

                TokenData storage currSlot = _tokenData[tokenId];
                currSlot.owner = to;
                currSlot.lastTransfer = uint40(block.timestamp);
                currSlot.nextTokenDataSet = true;
                if (currSlot.ownerCount < type(uint24).max) ++currSlot.ownerCount;

                if (!tokenData.nextTokenDataSet) {
                    // If the ownership slot of tokenId+1 is not explicitly set, that means the transfer initiator owns it.
                    // Set the slot of tokenId+1 explicitly in storage to maintain correctness for ownerOf(tokenId+1) calls.
                    uint256 nextTokenId = tokenId + 1;
                    TokenData storage nextSlot = _tokenData[nextTokenId];
                    if (
                        nextSlot.owner == address(0) &&
                        // && nextTokenId != _currentIndex
                        nextTokenId != startingIndex + collectionSize // it's ok to check collectionSize instead of _currentIndex
                    ) {
                        nextSlot.owner = from;
                        nextSlot.lastTransfer = tokenData.lastTransfer;
                    }
                }

                emit Transfer(from, to, tokenId);
            }
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
        UserData memory userData = _claimReward();
        for (uint256 i; i < tokenIds.length; ++i) userData = _stake(msg.sender, tokenIds[i], userData);
        _userData[msg.sender] = userData;
    }

    function unstake(uint256[] calldata tokenIds) external payable {
        UserData memory userData = _claimReward();
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
        UserData memory userData
    ) private returns (UserData memory) {
        TokenData memory tokenData = _tokenDataOf(tokenId);

        if (userData.numStaked >= stakingLimit) revert ExceedsStakingLimit();
        if (tokenData.owner != from || tokenData.staked) revert IncorrectOwner();

        delete getApproved[tokenId];

        // hook, used for reading DNA, updating role balances,
        // (uint256 userDataX, uint256 tokenDataX) = _beforeStakeDataTransform(tokenId, userData, tokenData);

        tokenData.staked = true;

        unchecked {
            --userData.balance;
            ++userData.numStaked;
        }

        if (userData.numStaked == 0) userData.stakeStart = uint40(block.timestamp);

        _tokenData[tokenId] = tokenData;

        emit Transfer(from, address(this), tokenId);

        return userData;
    }

    function _unstake(
        address to,
        uint256 tokenId,
        UserData memory userData
    ) private returns (UserData memory) {
        TokenData memory tokenData = _tokenDataOf(tokenId);

        if (tokenData.owner != to) revert IncorrectOwner();
        if (!tokenData.staked) revert TokenIdUnstaked();

        // (uint256 userDataX, uint256 tokenDataX) = _beforeUnstakeDataTransform(tokenId, userData, tokenData);
        // (userData, tokenData) = applySafeDataTransform(userData, tokenData, userDataX, tokenDataX);

        // if mintAndStake flag is set, we need to make sure that next tokenData is set
        // because tokenData in this case is implicit and needs to carry over
        if (tokenData.mintAndStaked) {
            unchecked {
                uint256 nextTokenId = tokenId + 1;
                if (!tokenData.nextTokenDataSet && _tokenData[nextTokenId].owner == address(0) && _exists(tokenId))
                    _tokenData[nextTokenId] = tokenData;

                tokenData.nextTokenDataSet = true;
                tokenData.mintAndStaked = false;
            }
        }

        tokenData.staked = false;
        _tokenData[tokenId] = tokenData;

        emit Transfer(address(this), to, tokenId);

        unchecked {
            ++userData.balance;
            --userData.numStaked;
        }
        userData.stakeStart = uint40(block.timestamp);

        return userData;
    }

    /* ------------- View ------------- */

    function tokenURI(uint256 id) public view virtual returns (string memory);

    function name() external view returns (string memory) {
        return _name;
    }

    function symbol() external view returns (string memory) {
        return _symbol;
    }

    function totalSupply() external view returns (uint256) {
        return _currentIndex - startingIndex;
    }

    function supportsInterface(bytes4 interfaceId) external view virtual returns (bool) {
        return
            interfaceId == 0x01ffc9a7 || // ERC165 Interface ID for ERC165
            interfaceId == 0x80ac58cd || // ERC165 Interface ID for ERC721
            interfaceId == 0x5b5e139f; // ERC165 Interface ID for ERC721Metadata
    }

    function balanceOf(address owner) public view returns (uint256) {
        return _userData[owner].balance;
    }

    function numMinted(address user) public view returns (uint256) {
        return _userData[user].numMinted;
    }

    function ownerOf(uint256 tokenId) public view returns (address) {
        TokenData memory tokenData = _tokenDataOf(tokenId);
        return tokenData.staked ? address(this) : tokenData.owner;
    }

    function trueOwnerOf(uint256 tokenId) public view returns (address) {
        return _tokenDataOf(tokenId).owner;
    }

    function numStaked(address user) public view returns (uint256) {
        return _userData[user].numStaked;
    }

    function numOwned(address user) public view returns (uint256) {
        UserData memory userData = _userData[user];
        return userData.balance + userData.numStaked;
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
            uint256 endIndex = _currentIndex;
            TokenData memory tokenData;

            for (uint256 i = startingIndex; i < endIndex; ++i) {
                tokenData = _tokenDataOf(i);
                if (user == tokenData.owner) {
                    if ((type_ == 0 && !tokenData.staked) || (type_ == 1 && tokenData.staked) || type_ == 2) {
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
            uint256 endIndex = _currentIndex;
            for (uint256 i = startingIndex; i < endIndex; ++i) {
                if (_tokenDataOf(i).staked) ++count;
            }
            return count;
        }
    }

    /* ------------- Internal ------------- */

    function _exists(uint256 tokenId) internal view returns (bool) {
        return startingIndex <= tokenId && tokenId < _currentIndex;
    }

    function _tokenDataOf(uint256 tokenId) internal view returns (TokenData memory tokenData) {
        unchecked {
            if (!_exists(tokenId)) revert NonexistentToken();

            for (uint256 curr = tokenId; ; --curr) {
                tokenData = _tokenData[curr];
                if (tokenData.owner != address(0)) {
                    // @note need to watch out here if at any point aux data is introduced
                    // perhaps new TokenData should be created, this part is quite nuanced
                    if (tokenId == curr || tokenData.mintAndStaked) return tokenData;
                    tokenData.staked = false;
                    return tokenData;
                }
            }

            revert NonexistentToken();
        }
    }

    function _mintAndStake(
        address to,
        uint256 quantity,
        bool stake_
    ) internal {
        unchecked {
            if (to == address(0)) revert MintToZeroAddress();
            if (quantity == 0) revert MintZeroQuantity();

            uint256 startTokenId = _currentIndex;
            uint256 supply = startTokenId - startingIndex;

            // we're assuming that this won't ever overflow, because
            // emitting that many events would cost too much gas
            // in most cases this is restricted by child contract
            if (supply + quantity > collectionSize) revert MintExceedsMaxSupply();

            UserData memory userData = _userData[to];

            userData.numMinted += uint40(quantity);

            if (userData.numMinted > maxPerWallet && to == msg.sender && address(this).code.length != 0)
                revert MintExceedsMaxPerWallet();

            // don't have to care about next token data if only minting one
            // could optimize to implicitly flag last token id of batch
            _tokenData[startTokenId] = TokenData(to, uint40(block.timestamp), 1, stake_, stake_, quantity == 1);

            if (stake_) {
                uint256 numStaked_ = userData.numStaked;

                userData = claimReward(userData);
                userData.numStaked += uint40(quantity);

                if (numStaked_ + quantity > stakingLimit) revert ExceedsStakingLimit();
                if (numStaked_ == 0) userData.stakeStart = uint40(block.timestamp);
            } else {
                userData.balance += uint40(quantity);
            }

            _userData[to] = userData;

            uint256 updatedIndex = startTokenId;
            uint256 end = updatedIndex + quantity;

            do {
                // (userData, tokenData) = _beforeStakeDataTransform(tokenId, userData, tokenData);
                emit Transfer(address(0), to, updatedIndex);
                if (stake_) emit Transfer(to, address(this), updatedIndex);
            } while (++updatedIndex != end);

            _currentIndex = updatedIndex;
        }
    }

    function _claimReward() internal returns (UserData memory) {
        UserData memory userData = _userData[msg.sender];
        return claimReward(userData);
    }

    function claimReward(UserData memory userData) private returns (UserData memory) {
        uint256 reward = _pendingReward(msg.sender, userData);

        userData.lastClaimed = uint40(block.timestamp);

        _payoutReward(msg.sender, reward);

        return userData;
    }

    /* ------------- Virtual (hooks) ------------- */

    // function _beforeStakeDataTransform(
    //     uint256, /* tokenId */
    //     uint256 userData,
    //     uint256 tokenData
    // ) internal view virtual returns (uint256, uint256) {
    //     return (userData, tokenData);
    // }

    // function _beforeUnstakeDataTransform(
    //     uint256, /* tokenId */
    //     uint256 userData,
    //     uint256 tokenData
    // ) internal view virtual returns (uint256, uint256) {
    //     return (userData, tokenData);
    // }

    function _pendingReward(address, UserData memory userData) internal view virtual returns (uint256);

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
