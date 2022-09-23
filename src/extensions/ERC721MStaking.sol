// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import {ERC721M, s} from "../ERC721M.sol";
import {UserDataOps} from "../ERC721MLibrary.sol";

/// @title ERC721M Staking Extension
/// @author phaze (https://github.com/0xPhaze/ERC721M)
/// @notice Currently untested!!
abstract contract ERC721MStaking is ERC721M {
    using UserDataOps for uint256;

    address public immutable token;

    constructor(address token_) {
        token = token_;
    }

    /* ------------- virtual ------------- */

    function rewardEndDate() public view virtual returns (uint256);

    function rewardDailyRate() public view virtual returns (uint256);

    function tokenURI(uint256 id) external view virtual override returns (string memory);

    /* ------------- view ------------- */

    function pendingReward(address user) public view virtual returns (uint256) {
        uint256 userData = s().userData[user];

        return _calculateReward(userData.numLocked(), userData.userLockStart());
    }

    /* ------------- public ------------- */

    function stake(address user, uint256[] calldata ids) public virtual {
        _claimReward(user);

        for (uint256 i; i < ids.length; ++i) _lock(user, ids[i]);
    }

    function unstake(address user, uint256[] calldata ids) public virtual {
        _claimReward(user);

        for (uint256 i; i < ids.length; ++i) _unlock(user, ids[i]);
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

        uint256 numStaked = userData.numLocked();
        uint256 lastClaimed = userData.userLockStart();

        if (numStaked != 0) {
            // only forego minting if numStaked == 0
            // checking for amount == 0 can lead to failed transactions
            uint256 amount = _calculateReward(numStaked, lastClaimed);

            IERC20Reward(token).mint(user, amount);
        }

        s().userData[user] = userData.setUserLockStart(block.timestamp);
    }

    function _mintAndStake(address to, uint256 quantity) internal virtual {
        _claimReward(to);

        _mintAndLock(to, quantity, true, 0);
    }
}

interface IERC20Reward {
    function mint(address to, uint256 quantity) external;
}
