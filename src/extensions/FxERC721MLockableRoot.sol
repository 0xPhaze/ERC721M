// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import {FxBaseRootTunnel} from "fx-portal/tunnel/FxBaseRootTunnel.sol";

import "../ERC721M.sol";

error Disabled();

/// @notice ERC721M FxPortal extension
/// @author phaze (https://github.com/0xPhaze/ERC721M)
abstract contract FxERC721MLockableRoot is FxBaseRootTunnel, ERC721M {
    /* ------------- Internal ------------- */

    function _mintLockedAndTransmit(address to, uint256 quantity) internal {
        uint256 startTokenId = startingIndex + s().totalSupply;

        _mintAndLock(to, quantity, true);

        uint256[] memory tokenIds = new uint256[](quantity);
        unchecked {
            for (uint256 i; i < quantity; ++i) tokenIds[i] = startTokenId + i;
        }

        _sendMessageToChild(abi.encode(true, to, tokenIds));
    }

    function _lockAndTransmit(address to, uint256[] calldata tokenIds) internal {
        unchecked {
            for (uint256 i; i < tokenIds.length; ++i) _lock(to, tokenIds[i]);
        }

        _sendMessageToChild(abi.encode(true, to, tokenIds));
    }

    // @note using `_unlockAndTransmit` is simple and easy
    // this assumes L1 state as the single source of truth
    // messages are always pushed L1 -> L2 without knowing state on L2
    // this means that NFTs should not be allowed to be traded/sold on L2
    function _unlockAndTransmit(address from, uint256[] calldata tokenIds) internal {
        unchecked {
            for (uint256 i; i < tokenIds.length; ++i) _unlock(from, tokenIds[i]);
        }

        _sendMessageToChild(abi.encode(false, from, tokenIds));
    }

    // @note using `_unlockWithProof` is the 'correct' way for transmitting messages L2 -> L1
    // validate ERC721 lock on L2 first, then unlock on L1 with tx inclusion proof
    // NFTs can be traded/sold on L2 if adapted to transfer from current owner to new `from`
    function _unlockWithProof(bytes calldata inputData) public virtual {
        bytes memory message = _validateAndExtractMessage(inputData);

        (address from, uint256[] memory tokenIds) = abi.decode(message, (address, uint256[]));

        uint256 length = tokenIds.length;

        unchecked {
            for (uint256 i; i < length; ++i) _unlock(from, tokenIds[i]);
        }
    }

    // not used
    function _processMessageFromChild(bytes memory) internal pure override {
        revert Disabled();
    }
}
