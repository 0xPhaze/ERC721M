// SPDX-License-Identifier: AGPL-3.0-only
pragma solidity ^0.8.0;

import {DSTestPlus} from "solmate/test/utils/DSTestPlus.sol";
import {Vm} from "forge-std/Vm.sol";
import {console} from "forge-std/console.sol";

import "../ERC721MLockable.sol";
import {MockERC721MLockable} from "./mocks/MockERC721MLockable.sol";

contract ERC721MLockableTest is DSTestPlus {
    Vm vm = Vm(HEVM_ADDRESS);

    address alice = address(0x101);
    address bob = address(0x102);
    address chris = address(0x103);
    address tester = address(this);

    MockERC721MLockable token;

    function setUp() public {
        token = new MockERC721MLockable("Token", "TKN", 1, 30, 10);

        vm.label(alice, "Alice");
        vm.label(bob, "Bob");
        vm.label(chris, "Chris");

        vm.label(tester, "Tester");
        vm.label(address(token), "ERC721MLockable");
    }

    /* ------------- stake() ------------- */
    function test_stakeUnstake() public {
        token.mint(tester, 1);

        uint256[] memory ids = new uint256[](1);
        ids[0] = 1;

        token.stake(ids);

        assertEq(token.balanceOf(tester), 0);
        assertEq(token.numMinted(tester), 1);
        assertEq(token.numStaked(tester), 1);

        assertEq(token.ownerOf(1), address(token));
        assertEq(token.trueOwnerOf(1), tester);

        token.unstake(ids);

        assertEq(token.balanceOf(tester), 1);
        assertEq(token.numMinted(tester), 1);
        assertEq(token.numStaked(tester), 0);

        assertEq(token.ownerOf(1), tester);
        assertEq(token.trueOwnerOf(1), tester);
    }

    function test_mintAndStake5Unstake() public {
        token.mintAndStake(tester, 5);

        assertEq(token.balanceOf(tester), 0);
        assertEq(token.numMinted(tester), 5);
        assertEq(token.numStaked(tester), 5);

        for (uint256 i; i < 5; ++i) assertEq(token.ownerOf(i + 1), address(token));
        for (uint256 i; i < 5; ++i) assertEq(token.trueOwnerOf(i + 1), tester);

        uint256[] memory ids = new uint256[](5);
        for (uint256 i; i < 5; ++i) ids[i] = i + 1;

        token.unstake(ids);

        for (uint256 i; i < 5; ++i) assertEq(token.ownerOf(i + 1), tester);
        for (uint256 i; i < 5; ++i) assertEq(token.trueOwnerOf(i + 1), tester);
    }

    function test_mintAndStakeManyUnstake() public {
        token.mintAndStake(alice, 10);
        token.mintAndStake(tester, 10);

        for (uint256 i; i < 10; ++i) assertEq(token.ownerOf(i + 11), address(token));
        for (uint256 i; i < 10; ++i) assertEq(token.trueOwnerOf(i + 11), tester);

        uint256[] memory ids = new uint256[](4);
        ids[0] = 13;
        ids[1] = 14;
        ids[2] = 17;
        ids[3] = 20;

        token.unstake(ids);

        assertEq(token.ownerOf(11), address(token));
        assertEq(token.ownerOf(12), address(token));
        assertEq(token.ownerOf(13), tester);
        assertEq(token.ownerOf(14), tester);
        assertEq(token.ownerOf(15), address(token));
        assertEq(token.ownerOf(16), address(token));
        assertEq(token.ownerOf(17), tester);
        assertEq(token.ownerOf(18), address(token));
        assertEq(token.ownerOf(19), address(token));
        assertEq(token.ownerOf(20), tester);
    }

    function test_stakeUnstakeMany() public {
        token.mint(tester, 10);

        uint256[] memory ids = new uint256[](3);
        ids[0] = 3;
        ids[1] = 4;
        ids[2] = 7;

        token.stake(ids);

        assertEq(token.balanceOf(tester), 7);
        assertEq(token.numMinted(tester), 10);
        assertEq(token.numStaked(tester), 3);

        assertEq(token.ownerOf(1), tester);
        assertEq(token.ownerOf(2), tester);
        assertEq(token.ownerOf(3), address(token));
        assertEq(token.ownerOf(4), address(token));
        assertEq(token.ownerOf(5), tester);
        assertEq(token.ownerOf(6), tester);
        assertEq(token.ownerOf(7), address(token));
        assertEq(token.ownerOf(8), tester);
        assertEq(token.ownerOf(9), tester);
        assertEq(token.ownerOf(10), tester);

        for (uint256 i; i < 10; ++i) assertEq(token.trueOwnerOf(i + 1), tester);

        token.unstake(ids);

        for (uint256 i; i < 10; ++i) assertEq(token.ownerOf(i + 1), tester);
        for (uint256 i; i < 10; ++i) assertEq(token.trueOwnerOf(i + 1), tester);
    }

    /* ------------- mint() ------------- */

    function test_mint() public {
        token.mint(alice, 1);

        assertEq(token.balanceOf(alice), 1);
        assertEq(token.numMinted(alice), 1);
        assertEq(token.ownerOf(1), alice);
    }

    function test_mintFive() public {
        token.mint(alice, 5);

        assertEq(token.balanceOf(alice), 5);
        assertEq(token.numMinted(alice), 5);
        for (uint256 i; i < 5; i++) assertEq(token.ownerOf(1), alice);
    }

    function test_mint_fail_MintToZeroAddress() public {
        vm.expectRevert(MintToZeroAddress.selector);
        token.mint(address(0), 1);
    }

    function test_mint_fail_MintExceedsMaxSupply() public {
        token.mint(bob, 10);
        token.mint(alice, 10);
        token.mint(chris, 10);

        vm.expectRevert(MintExceedsMaxSupply.selector);
        token.mint(tester, 1);
    }

    function test_mint_fail_MintExceedsMaxPerWallet() public {
        token.mint(tester, 10);

        vm.expectRevert(MintExceedsMaxPerWallet.selector);
        token.mint(tester, 1);
    }

    /* ------------- approve() ------------- */

    function test_approve() public {
        token.mint(tester, 1);

        token.approve(alice, 1);

        assertEq(token.getApproved(1), alice);
    }

    function test_approve_fail_NonexistentToken() public {
        vm.expectRevert(NonexistentToken.selector);
        token.approve(alice, 1);
    }

    function test_approve_fail_CallerNotOwnerNorApproved() public {
        token.mint(bob, 1);

        vm.expectRevert(CallerNotOwnerNorApproved.selector);
        token.approve(alice, 1);
    }

    function test_setApprovalForAll() public {
        token.setApprovalForAll(alice, true);

        assertTrue(token.isApprovedForAll(tester, alice));
    }

    /* ------------- transfer() ------------- */

    function test_transferFrom() public {
        token.mint(bob, 1);

        vm.prank(bob);
        token.approve(tester, 1);

        token.transferFrom(bob, alice, 1);

        assertEq(token.getApproved(1), address(0));
        assertEq(token.ownerOf(1), alice);
        assertEq(token.balanceOf(alice), 1);
        assertEq(token.balanceOf(bob), 0);
    }

    function test_transferFromSelf() public {
        token.mint(tester, 1);

        token.transferFrom(tester, alice, 1);

        assertEq(token.getApproved(1), address(0));
        assertEq(token.ownerOf(1), alice);
        assertEq(token.balanceOf(alice), 1);
        assertEq(token.balanceOf(tester), 0);
    }

    function test_transferFromApproveAll() public {
        token.mint(bob, 1);

        vm.prank(bob);
        token.setApprovalForAll(tester, true);

        token.transferFrom(bob, alice, 1);

        assertEq(token.getApproved(1), address(0));
        assertEq(token.ownerOf(1), alice);
        assertEq(token.balanceOf(alice), 1);
        assertEq(token.balanceOf(bob), 0);
    }

    function test_transferFrom_fail_NonexistentToken() public {
        vm.expectRevert(NonexistentToken.selector);
        token.transferFrom(bob, alice, 1);
    }

    function test_transferFrom_fail_TransferFromIncorrectOwner() public {
        token.mint(chris, 1);

        vm.expectRevert(TransferFromIncorrectOwner.selector);
        token.transferFrom(bob, alice, 1);
    }

    function test_transferFrom_fail_TransferToZeroAddress() public {
        token.mint(tester, 1);

        vm.expectRevert(TransferToZeroAddress.selector);
        token.transferFrom(tester, address(0), 1);
    }

    function test_transferFrom_fail_CallerNotOwnerNorApproved() public {
        token.mint(bob, 1);

        vm.expectRevert(CallerNotOwnerNorApproved.selector);
        token.transferFrom(bob, alice, 1);
    }

    /* ------------- transferFrom() edge-cases ------------- */

    function test_transferFrom1() public {
        token.mint(bob, 10);

        vm.prank(bob);
        token.transferFrom(bob, alice, 10);

        vm.expectRevert(NonexistentToken.selector);
        token.ownerOf(11);

        token.mint(alice, 1);

        assertEq(token.ownerOf(11), alice);
    }

    function test_transferFrom2() public {
        token.mint(bob, 29);

        vm.prank(bob);
        token.transferFrom(bob, alice, 10);
        token.mint(chris, 1);

        assertEq(token.ownerOf(30), chris);
    }

    function test_transferFrom3() public {
        token.mint(bob, 10);

        vm.prank(bob);
        token.transferFrom(bob, alice, 5);

        assertEq(token.ownerOf(5), alice);
        assertEq(token.ownerOf(6), bob);
    }
}
