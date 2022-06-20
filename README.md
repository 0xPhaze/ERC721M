# ERC721M (WIP)

src
- [ERC721MLibrary.sol](./src/ERC721MLibrary.sol) - "Library for bitmap manipulation"
- [ERC721MLockable.sol](./src/ERC721MLockable.sol) - "ERC721A-like with locking functionality"
- examples
  -   [ERC721MExample.sol](./src/ERC721MExample.sol)
- extensions
   -  [ERC721MStaking.sol](./src/ERC721MStaking.sol)
   -  [FxERC721MLockableRoot.sol](./src/FxERC721MLockableRoot.sol)
- test

[ERC721M](https://lovethewired.github.io/blog/2022/madmouse) allows for cheap and efficient staking.
Thus far, it has the cheapest gas costs on "minting and staking" directly.
The idea was first introduced in the [Mad Mouse Circus NFT](https://etherscan.io/address/0x3ad30c5e2985e960e89f4a28efc91ba73e104b77#code) project.

Implementation and tests are preliminary.
This should not be used in production until sufficiently tested.
I am not responsible for any damage caused using this contract.

Check [gas snapshot](.gas-snapshot) for more recent results.

| Function      | Gas ERC721AStaking | Gas ERC721MStaking |
| :------------ | :----------------: | :----------------: |
| mintAndStake1 |       180531       |       44105        |
| mintAndStake5 |       372912       |       59665        |
| stake1        |       150021       |       56418        |
| stake5        |       336684       |       149163       |


```
forge snapshot --match-contract StakingGasTest
```
