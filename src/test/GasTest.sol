// SPDX-License-Identifier: AGPL-3.0-only
pragma solidity ^0.8.0;

import {DSTestPlus} from "solmate/test/utils/DSTestPlus.sol";
import {Vm} from "forge-std/Vm.sol";

import {MockERC721A} from "./mocks/MockERC721A.sol";
import {MockERC721M} from "./mocks/MockERC721M.sol";
import {MockERC721MMC} from "./mocks/MockERC721MMC.sol";

import {ERC721AStaking} from "./lib/ERC721AStaking.sol";

contract GasTest is DSTestPlus {
    Vm vm = Vm(HEVM_ADDRESS);

    address alice = address(0x101);
    address bob = address(0x102);
    address chris = address(0x103);
    address tester = address(this);

    MockERC721A erc721a;
    MockERC721M erc721m;
    MockERC721MMC erc721mmc;

    ERC721AStaking erc721aStaking;

    uint256[] ids_1 = [1];
    uint256[] ids_5 = [1, 2, 3, 4, 5];

    function setUp() public {
        erc721a = new MockERC721A("Token", "TKN", 1, 30, 10);
        erc721m = new MockERC721M("Token", "TKN", 1, 30, 10);
        erc721mmc = new MockERC721MMC("Token", "TKN", 1, 30, 10);
        erc721aStaking = new ERC721AStaking(erc721a);

        vm.label(alice, "Alice");
        vm.label(bob, "Bob");
        vm.label(chris, "Chris");

        vm.label(tester, "TestContract");
        vm.label(address(erc721a), "ERC721A");
        vm.label(address(erc721m), "ERC721M");
        vm.label(address(erc721mmc), "ERC721MMC");
        vm.label(address(erc721aStaking), "ERC721AStaking");

        erc721a.mint(tester, 5);
        erc721m.mint(tester, 5);
        erc721mmc.mint(tester, 5);

        vm.startPrank(alice);
        erc721a.setApprovalForAll(tester, true);
        erc721m.setApprovalForAll(tester, true);
        erc721mmc.setApprovalForAll(tester, true);
        vm.stopPrank();

        vm.startPrank(bob);
        erc721a.setApprovalForAll(tester, true);
        erc721m.setApprovalForAll(tester, true);
        erc721mmc.setApprovalForAll(tester, true);
        vm.stopPrank();

        vm.startPrank(chris);
        erc721a.setApprovalForAll(tester, true);
        erc721m.setApprovalForAll(tester, true);
        erc721mmc.setApprovalForAll(tester, true);
        vm.stopPrank();

        // touch
        ids_1;
        ids_5;
    }

    /* ------------- mint() ------------- */

    function test_mint1_ERC721A() public {
        erc721a.mint(alice, 1);
    }

    function test_mint1_ERC721M() public {
        erc721m.mint(alice, 1);
    }

    function test_mint1_ERC721MMC() public {
        erc721mmc.mint(alice, 1);
    }

    function test_mint5_ERC721A() public {
        erc721a.mint(alice, 5);
    }

    function test_mint5_ERC721M() public {
        erc721m.mint(alice, 5);
    }

    function test_mint5_ERC721MMC() public {
        erc721mmc.mint(alice, 5);
    }

    /* ------------- stake() ------------- */

    function test_stake1_ERC721A() public {
        // debatable whether approval tx should be considered in gas comparison
        erc721a.setApprovalForAll(address(erc721aStaking), true);

        erc721aStaking.stake(ids_1);
    }

    function test_stake1_ERC721M() public {
        erc721m.stake(ids_1);
    }

    function test_stake1_ERC721MMC() public {
        erc721mmc.stake(ids_1);
    }

    function test_stake5_ERC721A() public {
        erc721a.setApprovalForAll(address(erc721aStaking), true);
        erc721aStaking.stake(ids_5);
    }

    function test_stake5_ERC721M() public {
        erc721m.stake(ids_5);
    }

    function test_stake5_ERC721MMC() public {
        erc721mmc.stake(ids_5);
    }

    /* ------------- mintAndStake() ------------- */

    function test_mintAndStake1_ERC721A() public {
        erc721a.mint(tester, 1);
        erc721a.setApprovalForAll(address(erc721aStaking), true);
        erc721aStaking.stake(ids_1);
    }

    function test_mintAndStake1_ERC721M() public {
        erc721m.mintAndStake(tester, 1);
    }

    function test_mintAndStake1_ERC721MMC() public {
        erc721mmc.mintAndStake(tester, 1);
    }

    function test_mintAndStake5_ERC721A() public {
        erc721a.mint(tester, 5);
        erc721a.setApprovalForAll(address(erc721aStaking), true);
        erc721aStaking.stake(ids_5);
    }

    function test_mintAndStake5_ERC721M() public {
        erc721m.mintAndStake(tester, 5);
    }

    function test_mintAndStake5_ERC721MMC() public {
        erc721mmc.mintAndStake(tester, 5);
    }

    /* ------------- transfer() ------------- */

    function test_transferFrom1_ERC721A() public {
        erc721a.transferFrom(tester, bob, 1);
    }

    function test_transferFrom1_ERC721M() public {
        erc721m.transferFrom(tester, bob, 1);
    }

    function test_transferFrom1_ERC721MMC() public {
        erc721mmc.transferFrom(tester, bob, 1);
    }

    function test_transferFrom5_ERC721A() public {
        erc721a.transferFrom(tester, bob, 1);
        erc721a.transferFrom(bob, alice, 1);
        erc721a.transferFrom(alice, chris, 1);
        erc721a.transferFrom(chris, bob, 1);
        erc721a.transferFrom(bob, alice, 1);
    }

    function test_transferFrom5_ERC721M() public {
        erc721m.transferFrom(tester, bob, 1);
        erc721m.transferFrom(bob, alice, 1);
        erc721m.transferFrom(alice, chris, 1);
        erc721m.transferFrom(chris, bob, 1);
        erc721m.transferFrom(bob, alice, 1);
    }

    function test_transferFrom5_ERC721MMC() public {
        erc721mmc.transferFrom(tester, bob, 1);
        erc721mmc.transferFrom(bob, alice, 1);
        erc721mmc.transferFrom(alice, chris, 1);
        erc721mmc.transferFrom(chris, bob, 1);
        erc721mmc.transferFrom(bob, alice, 1);
    }
}
