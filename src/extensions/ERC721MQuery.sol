// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "../ERC721MLibrary.sol";
import {ERC721M, s} from "../ERC721M.sol";

import "forge-std/Test.sol";

interface IERC20 {
    function mint(address to, uint256 quantity) external;
}

library utils {
    function getOwnedIds(
        mapping(uint256 => address) storage ownerOf,
        address user,
        uint256 start,
        uint256 collectionSize
    ) internal view returns (uint256[] memory ids) {
        uint256 memPtr;
        uint256 idsLength;

        assembly {
            ids := mload(0x40)
            memPtr := add(ids, 32)
        }

        unchecked {
            address currentOwner;
            address owner;
            uint256 end = collectionSize + start;
            for (uint256 id = start; id < end; ++id) {
                owner = ownerOf[id];
                if (owner != address(0)) currentOwner = owner;
                if (currentOwner == user) {
                    assembly {
                        mstore(memPtr, id)
                        memPtr := add(memPtr, 32)
                        idsLength := add(idsLength, 1)
                    }
                }
            }
        }

        assembly {
            mstore(ids, idsLength)
            mstore(0x40, memPtr)
        }
    }
}

/// @title ERC721M Query Extension
/// @author phaze (https://github.com/0xPhaze/ERC721M)
abstract contract ERC721MQuery is ERC721M {
    using UserDataOps for uint256;
    using TokenDataOps for uint256;

    /* ------------- O(n) read-only ------------- */

    function getOwnedIds(address user) external view returns (uint256[] memory) {
        mapping(uint256 => uint256) storage tokenData = s().tokenData;
        mapping(uint256 => address) storage ownerOf = s().getApproved;
        assembly { ownerOf.slot := tokenData.slot } // prettier-ignore
        return utils.getOwnedIds(ownerOf, user, startingIndex, totalSupply());
    }

    function totalNumLocked() external view returns (uint256) {
        uint256 count;
        uint256 endIndex = _nextTokenId();

        unchecked {
            for (uint256 i = startingIndex; i < endIndex; ++i) if (_tokenDataOf(i).locked()) ++count;
        }

        return count;
    }
}
