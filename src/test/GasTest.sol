// SPDX-License-Identifier: AGPL-3.0-only
pragma solidity ^0.8.0;

import {DSTestPlus} from "solmate/test/utils/DSTestPlus.sol";
import {Vm} from "forge-std/Vm.sol";

import {MockERC721M} from "./mocks/MockERC721M.sol";
import {MockERC721MMC} from "./mocks/MockERC721MMC.sol";

contract GasTest is DSTestPlus {
    Vm vm = Vm(HEVM_ADDRESS);

    address alice = address(0x101);
    address bob = address(0x102);
    address chris = address(0x103);
    address tester = address(this);

    MockERC721M erc721m;
    MockERC721MMC erc721mmc;

    function setUp() public {
        erc721m = new MockERC721M("Token", "TKN", 1, 30, 10);
        erc721mmc = new MockERC721MMC("Token", "TKN", 1, 30, 10);

        vm.label(alice, "Alice");
        vm.label(bob, "Bob");
        vm.label(chris, "Chris");

        vm.label(tester, "TestContract");
        vm.label(address(erc721m), "ERC721M");
        vm.label(address(erc721mmc), "ERC721MMC");

        erc721m.mint(tester, 5);
        erc721mmc.mint(tester, 5);

        vm.startPrank(alice);
        erc721m.setApprovalForAll(tester, true);
        erc721mmc.setApprovalForAll(tester, true);
        vm.stopPrank();

        vm.startPrank(bob);
        erc721m.setApprovalForAll(tester, true);
        erc721mmc.setApprovalForAll(tester, true);
        vm.stopPrank();

        vm.startPrank(chris);
        erc721m.setApprovalForAll(tester, true);
        erc721mmc.setApprovalForAll(tester, true);
        vm.stopPrank();
    }

    /* ------------- mint() ------------- */

    function test_mint1_ERC721M() public {
        erc721m.mint(alice, 1);
    }

    function test_mint1_ERC721MMC() public {
        erc721mmc.mint(alice, 1);
    }

    function test_mint5_ERC721M() public {
        erc721m.mint(alice, 5);
    }

    function test_mint5_ERC721MMC() public {
        erc721mmc.mint(alice, 5);
    }

    /* ------------- stake() ------------- */

    function test_stake1_ERC721M() public {
        uint256[] memory ids = new uint256[](1);
        ids[0] = 1;
        erc721m.stake(ids);
    }

    function test_stake1_ERC721MMC() public {
        uint256[] memory ids = new uint256[](1);
        ids[0] = 1;
        erc721mmc.stake(ids);
    }

    function test_stake5_ERC721M() public {
        uint256[] memory ids = new uint256[](5);
        for (uint256 i; i < 5; i++) ids[i] = i + 1;
        erc721m.stake(ids);
    }

    function test_stake5_ERC721MMC() public {
        uint256[] memory ids = new uint256[](5);
        for (uint256 i; i < 5; i++) ids[i] = i + 1;
        erc721mmc.stake(ids);
    }

    /* ------------- mintAndStake() ------------- */

    function test_mintAndStake1_ERC721M() public {
        erc721m.mintAndStake(alice, 1);
    }

    function test_mintAndStake1_ERC721MMC() public {
        erc721mmc.mintAndStake(alice, 1);
    }

    function test_mintAndStake5_ERC721M() public {
        erc721m.mintAndStake(alice, 5);
    }

    function test_mintAndStake5_ERC721MMC() public {
        erc721mmc.mintAndStake(alice, 5);
    }

    /* ------------- transfer() ------------- */

    function test_transferFrom1_ERC721M() public {
        erc721m.transferFrom(tester, bob, 1);
    }

    function test_transferFrom1_ERC721MMC() public {
        erc721mmc.transferFrom(tester, bob, 1);
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
