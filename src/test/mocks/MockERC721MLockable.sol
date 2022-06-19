// SPDX-License-Identifier: AGPL-3.0-only
pragma solidity >=0.8.0;

import {ERC721MLockable} from "../../ERC721MLockable.sol";

contract MockERC721MLockable is ERC721MLockable {
    constructor(
        string memory name,
        string memory symbol,
        uint256 collectionSize_
    ) ERC721MLockable(name, symbol, collectionSize_) {}

    function tokenURI(uint256) public pure virtual override returns (string memory) {}

    function mint(address to, uint256 quantity) public virtual {
        _mintAndLock(to, quantity, false);
    }

    function mintAndStake(address to, uint256 quantity) public virtual {
        _mintAndLock(to, quantity, true);
    }
}
