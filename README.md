# ERC721M

ERC721MLockable is adapted from the original ERC721M to be more general and simpler.
Extending the idea of ERC721A it allows for cheap and efficient locking.
This can be applied for staking or bridgeing NFTs to other chains (see extensions).

Thus far, it has the cheapest gas costs when it comes to "minting and staking" directly.
The idea was first introduced in the [Mad Mouse Circus NFT](https://etherscan.io/address/0x3ad30c5e2985e960e89f4a28efc91ba73e104b77#code) project.

ERC721MLockable is further compatible with the EIP-2535 Diamond Storage pattern
which is helpful when working with [upgradeable contracts](https://github.com/0xPhaze/UDS).

Project structure
- [ERC721MLibrary.sol](./src/ERC721MLibrary.sol) - Library for bitmap manipulation
- [ERC721MLockable.sol](./src/ERC721MLockable.sol) - ERC721A-like with locking functionality using Diamond Storage
- extensions
   -  [ERC721MStaking.sol](./src/extensions/ERC721MStaking.sol) - ERC721M staking extension, allows minting an ERC20 token as reward
   -  [FxERC721MLockableRoot.sol](./src/extensions/FxERC721MLockableRoot.sol) - FxPortal extension, allows NFT to be transferred to Polygon
- examples
  -   [ERC721MExample.sol](./src/example/ERC721MExample.sol) - An example contract that could be used for a ERC721M that allows staking
- test

Implementation and tests are preliminary.
This should not be used in production until sufficiently tested.
I am not responsible for any damage caused using this contract.

## Gas comparison to staking with ERC721A

| Function      | Gas ERC721AStaking | Gas ERC721MStaking |
| :------------ | :----------------: | :----------------: |
| mintAndStake1 |       180531       |       44105        |
| mintAndStake5 |       372912       |       59665        |
| stake1        |       150021       |       56418        |
| stake5        |       336684       |       149163       |

The tests and setup can be reviewed [here](./src/test/StakingGasTest.sol)

Check [gas snapshot](.gas-snapshot) for more recent results.

```
forge snapshot --match-contract StakingGasTest
```
