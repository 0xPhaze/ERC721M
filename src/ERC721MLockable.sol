// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./ERC721MLibrary.sol";
import {EIP712PermitUDS} from "UDS/EIP712PermitUDS.sol";

error IncorrectOwner();
error NonexistentToken();
error QueryForZeroAddress();
error CallerNotOwnerNorApproved();

error MintZeroQuantity();
error MintToZeroAddress();
error MintExceedsMaxSupply();

error TransferFromIncorrectOwner();
error TransferFromInvalidTo();
error TransferToNonERC721Receiver();
error TransferToZeroAddress();

error ApprovalToCaller();
error ApproveToCurrentOwner();

error TokenIdLocked();
error TokenIdUnlocked();

abstract contract ERC721MLockable is EIP712PermitUDS {
    using TokenDataOps for uint256;
    using UserDataOps for uint256;

    event Transfer(address indexed from, address indexed to, uint256 indexed id);
    event Approval(address indexed owner, address indexed spender, uint256 indexed id);
    event ApprovalForAll(address indexed owner, address indexed operator, bool approved);

    string public name;
    string public symbol;

    uint256 public totalSupply;
    uint256 public immutable maxSupply;

    uint256 constant startingIndex = 1;

    mapping(uint256 => address) public getApproved;
    mapping(address => mapping(address => bool)) public isApprovedForAll;
    mapping(uint256 => uint256) private _tokenData;
    mapping(address => uint256) internal _userData;

    constructor(
        string memory name_,
        string memory symbol_,
        uint256 maxSupply_
    ) {
        name = name_;
        symbol = symbol_;
        maxSupply = maxSupply_;
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
        if (to == TokenDataOps.warden || to == address(this)) revert TransferFromInvalidTo();
        uint256 tokenData = _tokenDataOf(tokenId);

        if (tokenData.owner() != from) revert TransferFromIncorrectOwner();

        bool isApprovedOrOwner = (msg.sender == from ||
            isApprovedForAll[from][msg.sender] ||
            getApproved[tokenId] == msg.sender);

        if (!isApprovedOrOwner) revert CallerNotOwnerNorApproved();
        if (to == address(0)) revert TransferToZeroAddress();

        delete getApproved[tokenId];

        unchecked {
            _ensureTokenDataSet(tokenId + 1, tokenData);
        }
        _tokenData[tokenId] = tokenData.setOwner(to).flagNextTokenDataSet();
        // .setLastTransfer(block.timestamp)
        // .incrementOwnerCount()

        _userData[from] = _userData[from].decreaseBalance(1);
        _userData[to] = _userData[to].increaseBalance(1);

        emit Transfer(from, to, tokenId);
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

    // EIP-4494 permit; differs from the current EIP
    function permit(
        address owner,
        address operator,
        uint256 deadline,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) public virtual {
        if (_usePermit(owner, operator, 1, deadline, v, r, s)) {
            isApprovedForAll[owner][operator] = true;
            emit ApprovalForAll(owner, operator, true);
        }
    }

    /* ------------- View ------------- */

    function balanceOf(address user) public view returns (uint256) {
        return _userData[user].balance();
    }

    function ownerOf(uint256 tokenId) public view returns (address) {
        return _tokenDataOf(tokenId).owner();
    }

    function trueOwnerOf(uint256 tokenId) public view returns (address) {
        return _tokenDataOf(tokenId).trueOwner();
    }

    function tokenURI(uint256 id) public view virtual returns (string memory);

    function supportsInterface(bytes4 interfaceId) public view virtual returns (bool) {
        return
            interfaceId == 0x01ffc9a7 || // ERC165 Interface ID for ERC165
            interfaceId == 0x80ac58cd || // ERC165 Interface ID for ERC721
            interfaceId == 0x5b5e139f; // ERC165 Interface ID for ERC721Metadata
    }

    /* ------------- O(n) Read-only ------------- */

    function tokenIdsOf(address user) private view returns (uint256[] memory) {
        uint256 balance = balanceOf(user);

        uint256[] memory ids = new uint256[](balance);

        if (balance == 0) return ids;

        uint256 count;

        unchecked {
            for (uint256 i = startingIndex; i < totalSupply + startingIndex; ++i) {
                if (user == _tokenDataOf(i).trueOwner()) {
                    ids[count++] = i;
                    if (balance == count) return ids;
                }
            }
        }

        return ids;
    }

    function totalNumLocked() external view returns (uint256) {
        unchecked {
            uint256 count;
            for (uint256 i = startingIndex; i < startingIndex + totalSupply; ++i) {
                if (_tokenDataOf(i).locked()) ++count;
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

        unchecked {
            for (uint256 curr = tokenId; ; curr--) {
                // @important: aux data will be copied as well
                uint256 tokenData = _tokenData[curr];
                if (tokenData != 0) return tokenData;
            }
        }

        // unreachable
        return 0;
    }

    function _ensureTokenDataSet(uint256 tokenId, uint256 tokenData) private {
        if (!tokenData.nextTokenDataSet() && _tokenData[tokenId] == 0 && _exists(tokenId))
            _tokenData[tokenId] = tokenData;
    }

    function _mint(address to, uint256 quantity) internal {
        _mintAndLock(to, quantity, false);
    }

    function _mintAndLock(
        address to,
        uint256 quantity,
        bool lock_
    ) internal {
        unchecked {
            if (to == address(0)) revert MintToZeroAddress();
            if (quantity == 0) revert MintZeroQuantity();

            uint256 supply = totalSupply;
            uint256 startTokenId = startingIndex + supply;

            if (supply + quantity > maxSupply) revert MintExceedsMaxSupply();

            // uint256 userData = _userData[to];

            uint256 tokenData = uint160(to);
            if (lock_) tokenData = tokenData.setMintAndLocked();

            // don't have to care about next token data if only minting one
            if (quantity == 1) tokenData = tokenData.flagNextTokenDataSet();

            if (lock_) {
                // @note: to reduce gas costs, user numLocked is not tracked
                // userData = userData.increaseNumLocked(quantity);

                uint256 tokenId;
                for (uint256 i; i < quantity; ++i) {
                    tokenId = startTokenId + i;

                    emit Transfer(address(0), to, tokenId);
                    emit Transfer(to, TokenDataOps.warden, tokenId);
                }
            } else {
                for (uint256 i; i < quantity; ++i) emit Transfer(address(0), to, startTokenId + i);
            }

            // @note: to reduce gas costs, user numLocked is not tracked, balances stay constant when locking
            _userData[to] = _userData[to].increaseNumMinted(quantity).increaseBalance(quantity);
            _tokenData[startTokenId] = tokenData;

            totalSupply = supply + quantity;
        }
    }

    function _lock(address from, uint256 tokenId) internal {
        uint256 tokenData = _tokenDataOf(tokenId);

        bool isApprovedOrOwner = (msg.sender == from ||
            isApprovedForAll[from][msg.sender] ||
            getApproved[tokenId] == msg.sender);

        if (!isApprovedOrOwner) revert CallerNotOwnerNorApproved();
        if (tokenData.owner() != from) revert IncorrectOwner();

        delete getApproved[tokenId];

        _tokenData[tokenId] = tokenData.lock();

        // @note: to reduce gas costs, user numLocked is not tracked, balances stay constant when locking
        // _userData[from] = _userData[from].decreaseBalance(1).increaseNumLocked(1).setLockStart(block.timestamp);

        emit Transfer(from, TokenDataOps.warden, tokenId);
    }

    function _unlock(address from, uint256 tokenId) internal {
        uint256 tokenData = _tokenDataOf(tokenId);

        bool isApprovedOrOwner = (msg.sender == from ||
            isApprovedForAll[from][msg.sender] ||
            getApproved[tokenId] == msg.sender);

        if (!isApprovedOrOwner) revert CallerNotOwnerNorApproved();
        if (!tokenData.locked()) revert TokenIdUnlocked();
        if (tokenData.trueOwner() != from) revert IncorrectOwner();

        // if mintAndLock flag is set, we need to make sure that next tokenData is set
        // because tokenData in this case is implicit and needs to carry over
        if (tokenData.mintAndLock()) {
            unchecked {
                _ensureTokenDataSet(tokenId + 1, tokenData);
                tokenData = tokenData.unsetMintAndLocked().flagNextTokenDataSet();
            }
        }

        _tokenData[tokenId] = tokenData.unlock();

        emit Transfer(TokenDataOps.warden, from, tokenId);
    }
}

interface IERC721Receiver {
    function onERC721Received(
        address operator,
        address from,
        uint256 id,
        bytes calldata data
    ) external returns (bytes4);
}
