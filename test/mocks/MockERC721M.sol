// SPDX-License-Identifier: MIT
pragma solidity >=0.8.0;

import "ERC721M/ERC721M.sol";
import "ERC721M/extensions/ERC721MQuery.sol";

import "UDS/proxy/UUPSUpgrade.sol";

contract MockERC721M is UUPSUpgrade, ERC721M, ERC721MQuery {
    constructor(string memory name, string memory symbol) ERC721M(name, symbol) {}

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

    function _authorizeUpgrade() internal override {}
}
