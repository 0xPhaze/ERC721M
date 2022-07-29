// SPDX-License-Identifier: MIT
pragma solidity >=0.8.0;

import "ERC721M/extensions/ERC721MStaking.sol";

contract MockERC721MStaking is ERC721MStaking {
    string public override name;
    string public override symbol;

    constructor(
        string memory name_,
        string memory symbol_,
        IERC20 tkn
    ) ERC721MStaking(tkn) {
        name = name_;
        symbol = symbol_;
    }

    function mint(address to, uint256 quantity) public {
        _mint(to, quantity);
    }

    function mintAndStake(address to, uint256 quantity) public {
        _mintAndStake(to, quantity);
    }

    function tokenURI(uint256) public pure override returns (string memory) {}
}
