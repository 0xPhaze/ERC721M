// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import {FxBaseRootTunnel} from "fx-portal/tunnel/FxBaseRootTunnel.sol";

import "../ERC721MLockable.sol";

error Disabled();

abstract contract FxERC721MLockableRoot is FxBaseRootTunnel, ERC721MLockable {
    /* ------------- Internal ------------- */

    function _mintLockedAndTransmit(address to, uint256 quantity) internal {
        uint256 startTokenId = startingIndex + ds().totalSupply;

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

    // @note this method assumes L1 state as the source of truth
    // messages are always only pushed L1 -> L2 without knowing state on L2
    function _unlockAndTransmit(address from, uint256[] calldata tokenIds) internal {
        unchecked {
            for (uint256 i; i < tokenIds.length; ++i) _unlock(from, tokenIds[i]);
        }

        _sendMessageToChild(abi.encode(false, from, tokenIds));
    }

    // // correct way to do it: validate ERC721 lock on L2 first, then unlock on L1
    // function unlock(bytes calldata inputData) public virtual {
    //     bytes memory message = _validateAndExtractMessage(inputData);

    //     (address from, address to, uint256[] memory tokenIds) = abi.decode(message, (address, address, uint256));

    //     uint256 tokenIdsLength = tokenIds.length;

    //     unchecked {
    //         for (uint256 i; i < tokenIdsLength; ++i) _unlock(from, to, tokenIds[i]);
    //     }
    // }

    // we don't process any messages from L2
    function _processMessageFromChild(bytes memory) internal pure override {
        revert Disabled();
    }
}
