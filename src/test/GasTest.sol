// SPDX-License-Identifier: AGPL-3.0-only
pragma solidity ^0.8.0;

import "forge-std/Test.sol";
import {MockERC20} from "solmate/test/utils/mocks/MockERC20.sol";

import {MockERC721A} from "./mocks/MockERC721A.sol";
import {MockERC721MStaking, IERC20} from "./mocks/MockERC721MStaking.sol";

import {ERC721AStakingToken} from "./lib/ERC721AStakingToken.sol";
import "./lib/ArrayUtils.sol";

contract StakingStakingGasTest is Test {
    using ArrayUtils for *;

    address alice = address(0x101);
    address bob = address(0x102);
    address chris = address(0x103);
    address tester = address(this);

    MockERC721A erc721a;
    MockERC721MStaking erc721m;

    MockERC20 erc721mToken;
    ERC721AStakingToken erc721aStaking;

    function setUp() public {
        erc721a = new MockERC721A("Token", "TKN");
        erc721aStaking = new ERC721AStakingToken(erc721a);

        erc721mToken = new MockERC20("Token", "TKN", 18);
        erc721m = new MockERC721MStaking("Token", "TKN", IERC20(address(erc721mToken)));

        vm.label(alice, "Alice");
        vm.label(bob, "Bob");
        vm.label(chris, "Chris");

        vm.label(tester, "TestContract");
        vm.label(address(erc721a), "ERC721A");
        vm.label(address(erc721m), "ERC721M");
        vm.label(address(erc721mToken), "ERC721MToken");
        vm.label(address(erc721aStaking), "ERC721AStakingToken");

        erc721a.mint(tester, 5);
        erc721m.mint(tester, 5);
    }

    /* ------------- mint() ------------- */

    function test_mint1_ERC721A() public {
        erc721a.mint(alice, 1);
    }

    function test_mint1_ERC721M() public {
        erc721m.mint(alice, 1);
    }

    function test_mint5_ERC721A() public {
        erc721a.mint(alice, 5);
    }

    function test_mint5_ERC721M() public {
        erc721m.mint(alice, 5);
    }

    /* ------------- stake() ------------- */

    // debatable whether approval tx should be considered in gas comparison
    function test_stake1_ERC721A() public {
        erc721a.setApprovalForAll(address(erc721aStaking), true);
        erc721aStaking.stake([1].toMemory());
    }

    function test_stake5_ERC721A() public {
        erc721a.setApprovalForAll(address(erc721aStaking), true);
        erc721aStaking.stake([1, 2, 3, 4, 5].toMemory());
    }

    function test_stake1_ERC721M() public {
        erc721m.stake([1].toMemory());
    }

    function test_stake5_ERC721M() public {
        erc721m.stake([1, 2, 3, 4, 5].toMemory());
    }

    /* ------------- mintAndStake() ------------- */

    function test_mintAndStake1_ERC721A() public {
        erc721a.mint(tester, 1);
        erc721a.setApprovalForAll(address(erc721aStaking), true);
        erc721aStaking.stake([1].toMemory());
    }

    function test_mintAndStake5_ERC721A() public {
        erc721a.mint(tester, 5);
        erc721a.setApprovalForAll(address(erc721aStaking), true);
        erc721aStaking.stake([1, 2, 3, 4, 5].toMemory());
    }

    function test_mintAndStake1_ERC721M() public {
        erc721m.mintAndStake(tester, 1);
    }

    function test_mintAndStake5_ERC721M() public {
        erc721m.mintAndStake(tester, 5);
    }
}
