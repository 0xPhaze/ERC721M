// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./ERC721MLibrary.sol";
import {EIP712PermitUDS as EIP712Permit} from "UDS/auth/EIP712PermitUDS.sol";

// ------------- storage

struct ERC721MStorage {
    uint256 totalSupply;
    mapping(uint256 => address) getApproved;
    mapping(address => mapping(address => bool)) isApprovedForAll;
    mapping(uint256 => uint256) tokenData;
    mapping(address => uint256) userData;
}

// keccak256("diamond.storage.erc721m.lockable") == 0xacef0a52ec0e8b948b85810f48a276692a03896348e0958ead290f1909a95599;
bytes32 constant DIAMOND_STORAGE_ERC721M_LOCKABLE = 0xacef0a52ec0e8b948b85810f48a276692a03896348e0958ead290f1909a95599;

function s() pure returns (ERC721MStorage storage diamondStorage) {
    assembly { diamondStorage.slot := DIAMOND_STORAGE_ERC721M_LOCKABLE } // prettier-ignore
}

// ------------- errors

error IncorrectOwner();
error TokenIdUnlocked();
error NonexistentToken();
error MintZeroQuantity();
error MintToZeroAddress();
error TransferFromInvalidTo();
error TransferToZeroAddress();
error CallerNotOwnerNorApproved();
error TransferFromIncorrectOwner();
error TransferToNonERC721Receiver();

/// @title ERC721M (Integrated Token Locking)
/// @author phaze (https://github.com/0xPhaze/ERC721M)
/// @author ERC721A (https://github.com/chiru-labs/ERC721A)
/// @author Solmate (https://github.com/Rari-Capital/solmate)
/// @notice Integrates EIP712Permit
abstract contract ERC721M is EIP712Permit {
    using TokenDataOps for uint256;
    using UserDataOps for uint256;

    event Transfer(address indexed from, address indexed to, uint256 indexed id);
    event Approval(address indexed owner, address indexed spender, uint256 indexed id);
    event ApprovalForAll(address indexed owner, address indexed operator, bool approved);

    uint256 constant startingIndex = 1;

    /* ------------- view ------------- */

    function name() external view virtual returns (string memory);

    function symbol() external view virtual returns (string memory);

    function tokenURI(uint256 id) external view virtual returns (string memory);

    function balanceOf(address user) public view returns (uint256) {
        return s().userData[user].balance();
    }

    function getApproved(uint256 id) external view returns (address) {
        return s().getApproved[id];
    }

    function isApprovedForAll(address owner, address spender) external view returns (bool) {
        return s().isApprovedForAll[owner][spender];
    }

    function ownerOf(uint256 id) public view returns (address) {
        return _tokenDataOf(id).owner(warden());
    }

    function warden() public view virtual returns (address) {
        return address(this);
    }

    function totalSupply() public view returns (uint256) {
        return s().totalSupply;
    }

    function numMinted(address user) public view returns (uint256) {
        return s().userData[user].numMinted();
    }

    function trueOwnerOf(uint256 id) public view returns (address) {
        return _tokenDataOf(id).trueOwner();
    }

    function supportsInterface(bytes4 interfaceId) public view virtual returns (bool) {
        return
            interfaceId == 0x01ffc9a7 || // ERC165 Interface ID for ERC165
            interfaceId == 0x80ac58cd || // ERC165 Interface ID for ERC721
            interfaceId == 0x5b5e139f; // ERC165 Interface ID for ERC721Metadata
    }

    /* ------------- public ------------- */

    function approve(address spender, uint256 id) public virtual {
        address owner = _tokenDataOf(id).owner(warden());

        if (msg.sender != owner && !s().isApprovedForAll[owner][msg.sender]) revert CallerNotOwnerNorApproved();

        s().getApproved[id] = spender;

        emit Approval(owner, spender, id);
    }

    function setApprovalForAll(address operator, bool approved) public virtual {
        s().isApprovedForAll[msg.sender][operator] = approved;

        emit ApprovalForAll(msg.sender, operator, approved);
    }

    function _isApprovedOrOwner(address from, uint256 id) private view returns (bool) {
        return (msg.sender == from || s().isApprovedForAll[from][msg.sender] || s().getApproved[id] == msg.sender);
    }

    function transferFrom(
        address from,
        address to,
        uint256 id
    ) public virtual {
        if (to == address(0)) revert TransferToZeroAddress();
        if (to == warden()) revert TransferFromInvalidTo();

        uint256 tokenData = _tokenDataOf(id);

        bool isApprovedOrOwner = (msg.sender == from ||
            s().isApprovedForAll[from][msg.sender] ||
            s().getApproved[id] == msg.sender);

        if (tokenData.owner(warden()) != from) revert TransferFromIncorrectOwner();
        if (!isApprovedOrOwner) revert CallerNotOwnerNorApproved();

        delete s().getApproved[id];

        unchecked {
            _ensureTokenDataSet(id + 1, tokenData);
        }

        s().tokenData[id] = tokenData.setOwner(to).flagNextTokenDataSet();

        s().userData[from] = s().userData[from].decreaseBalance(1);
        s().userData[to] = s().userData[to].increaseBalance(1);

        emit Transfer(from, to, id);
    }

    function safeTransferFrom(
        address from,
        address to,
        uint256 id
    ) public virtual {
        safeTransferFrom(from, to, id, "");
    }

    function safeTransferFrom(
        address from,
        address to,
        uint256 id,
        bytes memory data
    ) public virtual {
        transferFrom(from, to, id);
        if (
            to.code.length != 0 &&
            IERC721Receiver(to).onERC721Received(msg.sender, from, id, data) !=
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
        bytes32 s_
    ) public virtual {
        if (_usePermit(owner, operator, 1, deadline, v, r, s_)) {
            s().isApprovedForAll[owner][operator] = true;

            emit ApprovalForAll(owner, operator, true);
        }
    }

    /* ------------- O(n) Read-only ------------- */

    function tokenIdsOf(address user) external view returns (uint256[] memory) {
        uint256 balance = balanceOf(user);

        uint256[] memory ids = new uint256[](balance);

        if (balance == 0) return ids;

        uint256 count;
        uint256 endIndex = _nextTokenId();

        unchecked {
            for (uint256 i = startingIndex; i < endIndex; ++i) {
                if (user == _tokenDataOf(i).trueOwner()) {
                    ids[count++] = i;
                    if (balance == count) return ids;
                }
            }
        }

        return ids;
    }

    function totalNumLocked() external view returns (uint256) {
        uint256 count;
        uint256 endIndex = _nextTokenId();

        unchecked {
            for (uint256 i = startingIndex; i < endIndex; ++i) if (_tokenDataOf(i).locked()) ++count;
        }

        return count;
    }

    /* ------------- internal ------------- */

    function _exists(uint256 id) internal view returns (bool) {
        return startingIndex <= id && id < _nextTokenId();
    }

    function _nextTokenId() internal view returns (uint256) {
        return startingIndex + s().totalSupply;
    }

    function _tokenDataOf(uint256 id) internal view returns (uint256) {
        if (!_exists(id)) revert NonexistentToken();

        unchecked {
            uint256 tokenData;

            for (uint256 curr = id; ; curr--) {
                tokenData = s().tokenData[curr];

                if (tokenData != 0) return curr == id ? tokenData : tokenData.copy();
            }
        }

        // unreachable
        return 0;
    }

    function _ensureTokenDataSet(uint256 id, uint256 tokenData) internal {
        if (!tokenData.nextTokenDataSet() && s().tokenData[id] == 0 && _exists(id)) s().tokenData[id] = tokenData;
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

            uint256 supply = s().totalSupply;
            uint256 startTokenId = startingIndex + supply;

            uint256 tokenData = uint160(to);
            if (lock_) tokenData = tokenData.setConsecutiveLocked().lock();

            // don't have to care about next token data if only minting one
            if (quantity == 1) tokenData = tokenData.flagNextTokenDataSet();

            if (lock_) {
                // @note: to reduce gas costs when locking individually, user numLocked is not tracked
                // userData = userData.increaseNumLocked(quantity).setLockStart(block.timestamp);

                uint256 id;
                for (uint256 i; i < quantity; ++i) {
                    id = startTokenId + i;

                    emit Transfer(address(0), to, id);
                    emit Transfer(to, warden(), id);
                }
            } else {
                for (uint256 i; i < quantity; ++i) emit Transfer(address(0), to, startTokenId + i);
            }

            // @note: to reduce gas costs, user numLocked is not tracked, balances stay constant when locking
            s().userData[to] = s().userData[to].increaseNumMinted(quantity).increaseBalance(quantity);
            s().tokenData[startTokenId] = tokenData;

            s().totalSupply = supply + quantity;
        }
    }

    function _lock(address from, uint256 id) internal {
        uint256 tokenData = _tokenDataOf(id);

        bool isApprovedOrOwner = (msg.sender == from ||
            s().isApprovedForAll[from][msg.sender] ||
            s().getApproved[id] == msg.sender);

        if (!isApprovedOrOwner) revert CallerNotOwnerNorApproved();
        if (tokenData.owner(warden()) != from) revert IncorrectOwner();

        delete s().getApproved[id];

        s().tokenData[id] = tokenData.lock();

        unchecked {
            _ensureTokenDataSet(id + 1, tokenData);

            tokenData = tokenData.unsetConsecutiveLocked().flagNextTokenDataSet();
        }

        // @note: to reduce gas costs, user numLocked is not tracked, balances stay constant when locking
        // s().userData[from] = s().userData[from].decreaseBalance(1).increaseNumLocked(1).setLockStart(block.timestamp);

        emit Transfer(from, warden(), id);
    }

    function _unlock(address from, uint256 id) internal {
        uint256 tokenData = _tokenDataOf(id);

        bool isApprovedOrOwner = (msg.sender == from ||
            s().isApprovedForAll[from][msg.sender] ||
            s().getApproved[id] == msg.sender);

        if (!isApprovedOrOwner) revert CallerNotOwnerNorApproved();
        if (!tokenData.locked()) revert TokenIdUnlocked();
        if (tokenData.trueOwner() != from) revert IncorrectOwner();

        // if isConsecutiveLocked flag is set, we need to make sure that next tokenData is set
        // because tokenData in this case is implicit and needs to carry over
        if (tokenData.isConsecutiveLocked()) {
            unchecked {
                _ensureTokenDataSet(id + 1, tokenData);

                tokenData = tokenData.unsetConsecutiveLocked().flagNextTokenDataSet();
            }
        }

        s().tokenData[id] = tokenData.unlock();

        emit Transfer(warden(), from, id);
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
