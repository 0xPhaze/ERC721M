// SPDX-License-Identifier: AGPL-3.0-only
pragma solidity ^0.8.0;

import {ERC721A} from "ERC721A/ERC721A.sol";

error MintExceedsMaxSupply();
error MintExceedsMaxPerWallet();
error MintExceedsMaxPerTx();

contract MockERC721A is ERC721A {
    uint256 immutable collectionSize;
    uint256 immutable maxPerWallet;
    uint256 constant maxPerTx = 100;

    constructor(
        string memory name,
        string memory symbol,
        uint256, /* startingIndex_ */
        uint256 collectionSize_,
        uint256 maxPerWallet_
    ) ERC721A(name, symbol) {
        collectionSize = collectionSize_;
        maxPerWallet = maxPerWallet_;
    }

    // cannot be immutable in override and we don't want an extra sload to skew results
    function _startTokenId() internal pure override returns (uint256) {
        return 1;
    }

    function mint(address user, uint256 quantity) external {
        unchecked {
            if (quantity > maxPerTx) revert MintExceedsMaxPerTx();

            uint256 supply = _totalMinted();
            if (supply + quantity > collectionSize) revert MintExceedsMaxSupply();
            if (_numberMinted(user) + quantity > maxPerWallet) revert MintExceedsMaxPerWallet();
            _mint(user, quantity);
        }
    }
}
