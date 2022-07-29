// SPDX-License-Identifier: AGPL-3.0-only
pragma solidity >=0.8.0;

import "ERC721M/ERC721M.sol";

contract MockERC721M is ERC721M {
    string public override name;
    string public override symbol;

    constructor(string memory name_, string memory symbol_) {
        name = name_;
        symbol = symbol_;
    }

    function mint(address to, uint256 quantity) public {
        _mint(to, quantity);
    }

    function mintAndLock(address to, uint256 quantity) public {
        _mintAndLock(to, quantity, true);
    }

    function lockFrom(address from, uint256[] calldata tokenIds) public {
        for (uint256 i; i < tokenIds.length; ++i) _lock(from, tokenIds[i]);
    }

    function unlockFrom(address from, uint256[] calldata tokenIds) public {
        for (uint256 i; i < tokenIds.length; ++i) _unlock(from, tokenIds[i]);
    }

    function tokenURI(uint256) public pure override returns (string memory) {}
}
