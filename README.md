# ERC721M (WIP)

```ml
src
├── ERC721M.sol - "Written using structs as seen in ERC721A"
├── ERC721MMC.sol - "Written using uint256 bitmaps (cheaper) as used by Mad Mouse Circus"
└── ERC721MMCLibrary.sol "Library for bitmap manipulation"
```

src
├── [ERC721M.sol](.src/ERC721MLockable.sol) - "Written using structs as seen in ERC721A"
├── ERC721MMC.sol - "Written using uint256 bitmaps (cheaper) as used by Mad Mouse Circus"
└── ERC721MMCLibrary.sol "Library for bitmap manipulation"

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
