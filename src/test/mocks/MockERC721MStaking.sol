// SPDX-License-Identifier: AGPL-3.0-only
pragma solidity >=0.8.0;

import "../../extensions/ERC721MStaking.sol";

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
        _mintAndLock(to, quantity, true);
    }

    function stake(uint256[] calldata tokenIds) public {
        _stake(msg.sender, tokenIds);
    }

    function unstake(uint256[] calldata tokenIds) public {
        _unstake(msg.sender, tokenIds);
    }

    function tokenURI(uint256) public pure override returns (string memory) {}
}
