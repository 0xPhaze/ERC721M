// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "../ERC721MLibrary.sol";
import {ERC721M} from "../ERC721M.sol";

// ------------- interface

interface IERC20 {
    function mint(address to, uint256 quantity) external;
}

// ------------- storage

// keccak256("diamond.storage.erc721m.staking") == 0xa05bc11cf2ccffd87059baa494bcd69d85db615f89bba246bab170d688cc8332;
bytes32 constant DIAMOND_STORAGE_ERC721M_STAKING = 0xa05bc11cf2ccffd87059baa494bcd69d85db615f89bba246bab170d688cc8332;

function s() pure returns (ERC721MStakingDS storage diamondStorage) {
    assembly { diamondStorage.slot := DIAMOND_STORAGE_ERC721M_STAKING } // prettier-ignore
}

struct UserData {
    uint216 multiplier;
    uint40 lastClaimed;
}

struct ERC721MStakingDS {
    mapping(address => UserData) userData;
}

/// @title ERC721M Staking Extension
/// @author phaze (https://github.com/0xPhaze/ERC721M)
abstract contract ERC721MStaking is ERC721M {
    IERC20 public immutable token;

    constructor(IERC20 token_) {
        token = token_;
    }

    /* ------------- virtual ------------- */

    function rewardEndDate() public view virtual returns (uint256);

    function rewardDailyRate() public view virtual returns (uint256);

    /* ------------- view ------------- */

    function pendingReward(address user) public view virtual returns (uint256) {
        UserData storage userData = s().userData[user];

        return _calculateReward(userData.multiplier, userData.lastClaimed);
    }

    function numStaked(address user) public view virtual returns (uint256) {
        return s().userData[user].multiplier;
    }

    /* ------------- public ------------- */

    function stake(address user, uint256[] calldata ids) public virtual {
        _claimReward(user);

        for (uint256 i; i < ids.length; ++i) _lock(user, ids[i]);

        // safe to assume that an ids[] of length 2^216
        // is impossible due to gas constraints
        s().userData[user].multiplier += uint216(ids.length);
    }

    function unstake(address user, uint256[] calldata ids) public virtual {
        _claimReward(user);

        for (uint256 i; i < ids.length; ++i) _unlock(user, ids[i]);

        s().userData[user].multiplier -= uint216(ids.length);
    }

    /* ------------- internal ------------- */

    function _calculateReward(uint256 multiplier, uint256 lastClaimed) internal view virtual returns (uint256) {
        uint256 end = rewardEndDate();

        uint256 timestamp = block.timestamp;

        if (lastClaimed > end) return 0;
        else if (timestamp > end) timestamp = end;

        // if multiplier > 0 then lastClaimed > 0
        // because _claimReward must have been called
        return (multiplier * (timestamp - lastClaimed) * rewardDailyRate()) / 1 days;
    }

    function _claimReward(address user) internal virtual {
        UserData storage userData = s().userData[user];

        uint256 multiplier = userData.multiplier;
        uint256 lastClaimed = userData.lastClaimed;

        if (multiplier != 0 || lastClaimed == 0) {
            // only forego minting if multiplier == 0
            // checking for amount == 0 can lead to failed transactions
            if (multiplier != 0) {
                uint256 amount = _calculateReward(multiplier, lastClaimed);

                _mint(user, amount);
            }

            s().userData[user].lastClaimed = uint40(block.timestamp);
        }
    }

    function _mintAndStake(address to, uint256 quantity) internal virtual {
        _claimReward(to);

        _mintAndLock(to, quantity, true);

        s().userData[to].multiplier += uint216(quantity);
    }
}
