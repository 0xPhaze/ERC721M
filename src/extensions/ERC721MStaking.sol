// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "../ERC721MLibrary.sol";
import {ERC721MLockable, ds} from "../ERC721MLockable.sol";

interface IERC20 {
    function mint(address to, uint256 quantity) external;
}

abstract contract ERC721MStaking is ERC721MLockable {
    using UserDataOps for uint256;

    IERC20 public immutable token;

    constructor(IERC20 token_) {
        token = token_;
    }

    /* ------------- External ------------- */

    function claimReward() external virtual {
        ds().userData[msg.sender] = _claimReward(msg.sender);
    }

    /* ------------- View ------------- */

    function pendingReward(address user) public view virtual returns (uint256) {
        uint256 userData = ds().userData[user];

        unchecked {
            return (userData.numLocked() * 1e18 * (block.timestamp - userData.lockStart())) / (1 days);
        }
    }

    function numStaked(address user) public view virtual returns (uint256) {
        return ds().userData[user].numLocked();
    }

    /* ------------- Internal ------------- */

    function _stake(address user, uint256[] calldata tokenIds) internal virtual {
        unchecked {
            uint256 userData = _claimReward(user);

            for (uint256 i; i < tokenIds.length; ++i) _lock(user, tokenIds[i]);

            ds().userData[user] = userData.increaseNumLocked(tokenIds.length);
        }
    }

    function _unstake(address user, uint256[] calldata tokenIds) internal virtual {
        unchecked {
            uint256 userData = _claimReward(user);

            for (uint256 i; i < tokenIds.length; ++i) _unlock(user, tokenIds[i]);

            ds().userData[user] = userData.decreaseNumLocked(tokenIds.length);
        }
    }

    function _mintAndStake(address to, uint256 quantity) internal virtual {
        unchecked {
            uint256 userData = _claimReward(to);

            _mintAndLock(to, quantity, true);

            ds().userData[to] = userData.increaseNumLocked(quantity);
        }
    }

    // @note does not set userData
    function _claimReward(address user) private returns (uint256) {
        uint256 reward = pendingReward(user);

        token.mint(user, reward);

        return ds().userData[user].setLockStart(block.timestamp);
    }
}
