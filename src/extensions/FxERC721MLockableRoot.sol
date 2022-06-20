// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import {FxBaseRootTunnel} from "../../../lib/fx-portal/contracts/tunnel/FxBaseRootTunnel.sol";

import "../ERC721MLockable.sol";

error Disabled();

abstract contract FxERC721MLockableRoot is FxBaseRootTunnel, ERC721MLockable {
    // event FxUnlockERC721Batch(address indexed from, uint256[] tokenIds);
    // event FxLockERC721Batch(address indexed to, uint256[] tokenIds);

    /* ------------- Internal ------------- */

    function _mintLockedAndTransmit(address to, uint256 quantity) internal {
        uint256 startTokenId = startingIndex + totalSupply;

        _mintAndLock(to, quantity, true);

        uint256[] memory tokenIds = new uint256[](quantity);
        unchecked {
            for (uint256 i; i < quantity; ++i) tokenIds[i] = startTokenId + i;
        }

        _sendMessageToChild(abi.encode(true, to, tokenIds));

        // emit FxLockERC721Batch(to, tokenIds);
    }

    function _lockAndTransmit(address to, uint256[] calldata tokenIds) internal {
        unchecked {
            for (uint256 i; i < tokenIds.length; ++i) _lock(to, tokenIds[i]);
        }

        _sendMessageToChild(abi.encode(true, to, tokenIds));

        // emit FxLockERC721Batch(to, tokenIds);
    }

    // cheap/simple way: always push messages from L1 -> L2 without verifying state on L2
    function _unlockAndTransmit(address from, uint256[] calldata tokenIds) internal {
        unchecked {
            for (uint256 i; i < tokenIds.length; ++i) _unlock(from, tokenIds[i]);
        }

        _sendMessageToChild(abi.encode(false, from, tokenIds));

        // emit FxUnlockERC721Batch(from, tokenIds);
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

    function _processMessageFromChild(bytes memory) internal pure override {
        revert Disabled();
    }
}
