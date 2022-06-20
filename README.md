# ERC721M

ERC721MLockable is adapted from the original ERC721M to simpler and more general.
Extending the idea of ERC721A it allows for cheap and efficient locking.
This can be applied for staking or bridgeing NFTs to other chains (see extensions).

Thus far, it has the cheapest gas costs when "minting and staking" directly.
The idea was first introduced in the [Mad Mouse Circus NFT](https://etherscan.io/address/0x3ad30c5e2985e960e89f4a28efc91ba73e104b77#code) project.

src
- [ERC721MLibrary.sol](./src/ERC721MLibrary.sol) - "Library for bitmap manipulation"
- [ERC721MLockable.sol](./src/ERC721MLockable.sol) - "ERC721A-like with locking functionality using Diamond Storage"
- examples
  -   [ERC721MExample.sol](./src/example/ERC721MExample.sol)
- extensions
   -  [ERC721MStaking.sol](./src/extensions/ERC721MStaking.sol)
   -  [FxERC721MLockableRoot.sol](./src/extensions/FxERC721MLockableRoot.sol)
- test

Implementation and tests are preliminary.
This should not be used in production until sufficiently tested.
I am not responsible for any damage caused using this contract.

| Function      | Gas ERC721AStaking | Gas ERC721MStaking |
| :------------ | :----------------: | :----------------: |
| mintAndStake1 |       180531       |       44105        |
| mintAndStake5 |       372912       |       59665        |
| stake1        |       150021       |       56418        |
| stake5        |       336684       |       149163       |


Check [gas snapshot](.gas-snapshot) for more recent results.

```
forge snapshot --match-contract StakingGasTest
```
