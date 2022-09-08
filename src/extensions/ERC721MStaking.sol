// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import {ERC721M, s} from "../ERC721M.sol";

// ------------- interface

interface IERC20 {
    function mint(address to, uint256 quantity) external;
}

// ------------- library

/// @title ERC721M Staking Extension Library
/// @author phaze (https://github.com/0xPhaze/ERC721M)
/// @dev assumes projects have less than 2^20 total supply
library StakingDataOps {
    /* ------------- numStaked: [40, 60) ------------- */

    function numStaked(uint256 userData) internal pure returns (uint256) {
        return (userData >> 40) & 0xFFFFF;
    }

    function increaseNumStaked(uint256 userData, uint256 amount) internal pure returns (uint256) {
        return userData + (amount << 40);
    }

    function decreaseNumStaked(uint256 userData, uint256 amount) internal pure returns (uint256) {
        return userData - (amount << 40);
    }

    /* ------------- lastClaimed: [60, 100) ------------- */

    function lastClaimed(uint256 userData) internal pure returns (uint256) {
        return (userData >> 60) & 0xFFFFFFFFFF;
    }

    function setLastClaimed(uint256 userData, uint256 timestamp) internal pure returns (uint256) {
        return (userData & ~uint256(0xFFFFFFFFFF << 60)) | (timestamp << 60);
    }
}

/// @title ERC721M Staking Extension
/// @author phaze (https://github.com/0xPhaze/ERC721M)
abstract contract ERC721MStaking is ERC721M {
    using StakingDataOps for uint256;

    address public immutable token;

    constructor(address token_) {
        token = token_;
    }

    /* ------------- virtual ------------- */

    function rewardEndDate() public view virtual returns (uint256);

    function rewardDailyRate() public view virtual returns (uint256);

    /* ------------- view ------------- */

    function pendingReward(address user) public view virtual returns (uint256) {
        uint256 userData = s().userData[user];

        return _calculateReward(userData.numStaked(), userData.lastClaimed());
    }

    function stakedBalanceOf(address user) public view virtual returns (uint256) {
        return s().userData[user].numStaked();
    }

    /* ------------- public ------------- */

    function stake(address user, uint256[] calldata ids) public virtual {
        _claimReward(user);

        for (uint256 i; i < ids.length; ++i) _lock(user, ids[i]);

        s().userData[user] = s().userData[user].increaseNumStaked(ids.length);
    }

    function unstake(address user, uint256[] calldata ids) public virtual {
        _claimReward(user);

        for (uint256 i; i < ids.length; ++i) _unlock(user, ids[i]);

        s().userData[user] = s().userData[user].decreaseNumStaked(ids.length);
    }

    /* ------------- internal ------------- */

    function _calculateReward(uint256 numStaked, uint256 lastClaimed) internal view virtual returns (uint256) {
        uint256 end = rewardEndDate();

        uint256 timestamp = block.timestamp;

        if (lastClaimed > end) return 0;
        else if (timestamp > end) timestamp = end;

        // if numStaked > 0 then lastClaimed > 0
        // because _claimReward must have been called
        return (numStaked * (timestamp - lastClaimed) * rewardDailyRate()) / 1 days;
    }

    function _claimReward(address user) internal virtual {
        uint256 userData = s().userData[user];

        uint256 numStaked = userData.numStaked();
        uint256 lastClaimed = userData.lastClaimed();

        if (numStaked != 0 || lastClaimed == 0) {
            // only forego minting if numStaked == 0
            // checking for amount == 0 can lead to failed transactions
            if (numStaked != 0) {
                uint256 amount = _calculateReward(numStaked, lastClaimed);

                IERC20(token).mint(user, amount);
            }

            s().userData[user] = userData.setLastClaimed(block.timestamp);
        }
    }

    function _mintAndStake(address to, uint256 quantity) internal virtual {
        _claimReward(to);

        _mintAndLock(to, quantity, true);

        s().userData[to] = s().userData[to].increaseNumStaked(quantity);
    }
}
