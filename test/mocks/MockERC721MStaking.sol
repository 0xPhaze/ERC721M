// SPDX-License-Identifier: MIT
pragma solidity >=0.8.0;

import "ERC721M/extensions/ERC721MStaking.sol";

contract MockERC721MStaking is ERC721MStaking {
    uint256 private immutable _rewardEndDate = block.timestamp + 5 * 365 days;

    constructor(
        string memory name,
        string memory symbol,
        address tkn
    ) ERC721M(name, symbol) ERC721MStaking(tkn) {}

    function rewardEndDate() public view override returns (uint256) {
        return _rewardEndDate;
    }

    function rewardDailyRate() public pure override returns (uint256) {
        return 1e18;
    }

    function mint(address to, uint256 quantity) public {
        _mint(to, quantity);
    }

    function mintAndStake(address to, uint256 quantity) public {
        _mintAndStake(to, quantity);
    }

    function tokenURI(uint256) public pure override returns (string memory) {}
}
