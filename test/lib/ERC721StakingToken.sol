// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import {ERC20} from "solmate/tokens/ERC20.sol";
import {ERC721} from "solmate/tokens/ERC721.sol";

error IncorrectOwner();

/// @title Minimal Mock ERC721 Staking Contract
/// @notice Combined ERC20 Token to avoid external calls during claim
/// @author phaze (https://github.com/0xPhaze/ERC721M)
contract ERC721StakingToken is ERC20("Token", "TKN", 18) {
    struct StakeData {
        uint128 numStaked;
        uint128 lastClaimed;
    }

    mapping(uint256 => address) public ownerOf;
    mapping(address => StakeData) public stakeData;

    uint256 private constant rewardRate = 1e18;

    ERC721 immutable nft;

    constructor(ERC721 nft_) {
        nft = nft_;
    }

    /* ------------- external ------------- */

    function stake(uint256[] calldata ids) external {
        unchecked {
            claimReward();

            for (uint256 i; i < ids.length; ++i) {
                nft.transferFrom(msg.sender, address(this), ids[i]);

                ownerOf[ids[i]] = msg.sender;
            }

            stakeData[msg.sender].numStaked += uint128(ids.length);
        }
    }

    function unstake(uint256[] calldata ids) external {
        claimReward();

        for (uint256 i; i < ids.length; ++i) {
            if (ownerOf[ids[i]] != msg.sender) revert IncorrectOwner();

            delete ownerOf[ids[i]];

            nft.transferFrom(address(this), msg.sender, ids[i]);
        }

        stakeData[msg.sender].numStaked -= uint128(ids.length);
    }

    function claimReward() public {
        uint256 reward = pendingReward(msg.sender);

        _mint(msg.sender, reward);

        stakeData[msg.sender].lastClaimed = uint128(block.timestamp);
    }

    /* ------------- view ------------- */

    function pendingReward(address user) public view returns (uint256) {
        unchecked {
            return
                (stakeData[user].numStaked * rewardRate * (block.timestamp - stakeData[user].lastClaimed)) / (1 days);
        }
    }

    function numStaked(address user) external view returns (uint256) {
        return stakeData[user].numStaked;
    }
}
