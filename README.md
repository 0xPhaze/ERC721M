# ERC721M

ERC721MLockable (now simply ERC721M) is adapted from the original ERC721M to be more general and simpler.
Extending the idea of ERC721A it allows for cheap and efficient locking.
This can be applied for staking or bridging NFTs to other chains (see extensions).

Thus far, it has the cheapest gas costs when it comes to "minting and staking" directly.
The idea was first introduced in the [Mad Mouse Circus NFT](https://etherscan.io/address/0x3ad30c5e2985e960e89f4a28efc91ba73e104b77#code) project.

ERC721MLockable is further compatible with the EIP-2535 Diamond Storage pattern
which is helpful when working with [upgradeable contracts](https://github.com/0xPhaze/UDS).

## Contracts

```ml
src
├── ERC721M.sol - "ERC721A-like with locking functionality"
├── ERC721MLibrary.sol - "Library for bitmap manipulation"
├── examples
│   └── ERC721MExample.sol (@extensions) - "An example contract using `ERC721MStaking.sol`"
└── extensions
    ├── ERC721MStaking.sol (@extensions) - "ERC721M staking extension, allows minting an ERC20 token as reward"
    └── FxERC721MLockableRoot.sol (@extensions) - "FxPortal extension, allows NFT to be transferred to Polygon"
```

!All gas tests and comparisons and the Polygon FxPortal Extension are moved to the extensions branch to keep things simple and clean here!

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
