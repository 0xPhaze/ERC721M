# ERC721M (WIP)

```ml
src
├── ERC721M.sol - "Written using structs as seen in ERC721A"
├── ERC721MMC.sol - "Written using uint256 bitmaps (cheaper) as used by Mad Mouse Circus"
└── ERC721MMCLibrary.sol "Library for bitmap manipulation"
```

[ERC721M](https://lovethewired.github.io/blog/2022/madmouse) allows for cheap and efficient staking.
Thus far, it has the cheapest gas costs on "minting and staking" directly.
The idea was first introduced in the [Mad Mouse Circus NFT](https://etherscan.io/address/0x3ad30c5e2985e960e89f4a28efc91ba73e104b77#code) project.

Implementation and tests are preliminary.
This should not be used in production until sufficiently tested.
I am not responsible for any damage caused using this contract.

Check [gas snapshot](.gas-snapshot) for more recent results.

| Function                  | Gas    |
| ------------------------- | ------ |
| mintAndStake1_ERC721A()   | 180863 |
| mintAndStake1_ERC721M()   | 45601  |
| mintAndStake1_ERC721MMC() | 44628  |
| mintAndStake5_ERC721A()   | 390732 |
| mintAndStake5_ERC721M()   | 61184  |
| mintAndStake5_ERC721MMC() | 60181  |

```
forge snapshot --match-contract GasTest
```
