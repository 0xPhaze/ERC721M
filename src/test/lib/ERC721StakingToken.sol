// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import {ERC721A} from "ERC721A/ERC721A.sol";
import {ERC20} from "solmate/tokens/ERC20.sol";

error IncorrectOwner();

/// Minimal ERC721 staking contract
/// Combined ERC20 Token to avoid external calls during claim
/// @author phaze (https://github.com/0xPhaze/ERC721M)
contract ERC721StakingToken is ERC20("Token", "TKN", 18) {
    struct StakeData {
        uint128 numStaked;
        uint128 lastClaimed;
    }

    mapping(uint256 => address) public owners;
    mapping(address => StakeData) public stakeData;

    ERC721A immutable nft;

    constructor(ERC721A nft_) {
        nft = nft_;
    }

    /* ------------- External ------------- */

    function stake(uint256[] calldata tokenIds) external {
        unchecked {
            claimReward();

            for (uint256 i; i < tokenIds.length; ++i) {
                nft.transferFrom(msg.sender, address(this), tokenIds[i]);

                owners[tokenIds[i]] = msg.sender;
            }

            stakeData[msg.sender].numStaked += uint128(tokenIds.length);
        }
    }

    function unstake(uint256[] calldata tokenIds) external {
        unchecked {
            claimReward();

            for (uint256 i; i < tokenIds.length; ++i) {
                if (owners[tokenIds[i]] != msg.sender) revert IncorrectOwner();

                delete owners[tokenIds[i]];

                nft.transferFrom(address(this), msg.sender, tokenIds[i]);
            }

            stakeData[msg.sender].numStaked -= uint128(tokenIds.length);
        }
    }

    function claimReward() public {
        uint256 reward = pendingReward(msg.sender);

        _mint(msg.sender, reward);

        stakeData[msg.sender].lastClaimed = uint128(block.timestamp);
    }

    /* ------------- View ------------- */

    function pendingReward(address user) public view returns (uint256) {
        unchecked {
            return (stakeData[user].numStaked * 1e18 * (block.timestamp - stakeData[user].lastClaimed)) / (1 days);
        }
    }

    function numStaked(address user) public view returns (uint256) {
        return stakeData[user].numStaked;
    }
}
