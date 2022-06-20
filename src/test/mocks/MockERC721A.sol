// SPDX-License-Identifier: AGPL-3.0-only
pragma solidity ^0.8.0;

import {ERC721A} from "ERC721A/ERC721A.sol";

contract MockERC721A is ERC721A {
    constructor(string memory name, string memory symbol) ERC721A(name, symbol) {}

    function _startTokenId() internal pure override returns (uint256) {
        return 1;
    }

    function mint(address user, uint256 quantity) external {
        _mint(user, quantity);
    }
}
