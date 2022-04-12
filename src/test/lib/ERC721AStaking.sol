// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import {ERC721A} from "ERC721A/ERC721A.sol";

error IncorrectOwner();

contract ERC721AStaking {
    struct StakeData {
        uint128 numStaked;
        uint128 lastClaimed;
    }

    uint256 constant rewardPerDay = 1e18;

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

            uint256 tokenId;
            for (uint256 i; i < tokenIds.length; ++i) {
                tokenId = tokenIds[i];
                nft.transferFrom(msg.sender, address(this), tokenId);
                owners[tokenId] = msg.sender;
            }

            stakeData[msg.sender].numStaked += uint128(tokenIds.length);
        }
    }

    function unstake(uint256[] calldata tokenIds) external {
        unchecked {
            claimReward();

            uint256 tokenId;
            for (uint256 i; i < tokenIds.length; ++i) {
                tokenId = tokenIds[i];

                if (owners[tokenId] != msg.sender) revert IncorrectOwner();

                delete owners[tokenId];
                nft.transferFrom(address(this), msg.sender, tokenId);
            }

            stakeData[msg.sender].numStaked -= uint128(tokenIds.length);
        }
    }

    function claimReward() public {
        uint256 reward = pendingReward(msg.sender);
        // token.mint(msg.sender, reward);
        stakeData[msg.sender].lastClaimed = uint128(block.timestamp);
    }

    /* ------------- View ------------- */

    function pendingReward(address user) public view returns (uint256) {
        unchecked {
            return (stakeData[user].numStaked * 1e18 * (block.timestamp - stakeData[user].lastClaimed)) / (1 days);
        }
    }

    function numStaked(address user) external view returns (uint256) {
        return stakeData[user].numStaked;
    }

    function numOwned(address user) external view returns (uint256) {
        return nft.balanceOf(user) + stakeData[user].numStaked;
    }

    function totalNumStaked() external view returns (uint256) {
        return nft.balanceOf(address(this));
    }
}
