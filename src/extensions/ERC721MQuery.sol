// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "../ERC721MLibrary.sol";
import {ERC721M, s} from "../ERC721M.sol";

interface IERC20 {
    function mint(address to, uint256 quantity) external;
}

/// @title ERC721M Staking Extension
/// @author phaze (https://github.com/0xPhaze/ERC721M)
abstract contract ERC721MStaking is ERC721M {
    using UserDataOps for uint256;
    using TokenDataOps for uint256;

    /* ------------- O(n) read-only ------------- */

    function getOwnedIds(address user) external view returns (uint256[] memory) {
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
}
