// SPDX-License-Identifier: AGPL-3.0-only
pragma solidity ^0.8.0;

import "forge-std/Test.sol";

import "./mocks/MockERC721M.sol";
import "ArrayUtils/ArrayUtils.sol";

contract ERC721MTest is Test {
    using ArrayUtils for *;

    address alice = address(0xbabe);
    address bob = address(0xb0b);
    address tester = address(this);

    MockERC721M token;

    function setUp() public {
        token = new MockERC721M("Token", "TKN");

        vm.label(alice, "Alice");
        vm.label(bob, "Bob");
        vm.label(tester, "Tester");
        vm.label(address(token), "ERC721M");
    }

    /* ------------- lock() ------------- */

    function test_lockUnlock() public {
        token.mint(tester, 1);

        uint256[] memory ids = [1].toMemory();

        token.lockFrom(tester, ids);

        assertEq(token.balanceOf(tester), 1);
        assertEq(token.numMinted(tester), 1);

        assertEq(token.ownerOf(1), address(token));
        assertEq(token.trueOwnerOf(1), tester);

        token.unlockFrom(tester, ids);

        assertEq(token.balanceOf(tester), 1);
        assertEq(token.numMinted(tester), 1);

        assertEq(token.ownerOf(1), tester);
        assertEq(token.trueOwnerOf(1), tester);
    }

    function test_lockUnlock_fail() public {
        token.mint(alice, 1);
        token.mint(tester, 1);

        vm.expectRevert(CallerNotOwnerNorApproved.selector);
        token.lockFrom(alice, [1].toMemory());

        vm.expectRevert(IncorrectOwner.selector);
        token.lockFrom(tester, [1].toMemory());

        vm.expectRevert(CallerNotOwnerNorApproved.selector);
        token.lockFrom(alice, [1].toMemory());

        vm.prank(alice);
        token.lockFrom(alice, [1].toMemory());

        vm.expectRevert(IncorrectOwner.selector);
        token.unlockFrom(tester, [1].toMemory());

        vm.expectRevert(CallerNotOwnerNorApproved.selector);
        token.unlockFrom(alice, [1].toMemory());

        vm.expectRevert(IncorrectOwner.selector);
        token.lockFrom(tester, [2, 2].toMemory());

        token.lockFrom(tester, [2].toMemory());

        vm.expectRevert(TokenIdUnlocked.selector);
        token.unlockFrom(tester, [2, 2].toMemory());
    }

    function test_mintAndlock() public {
        token.mintAndLock(tester, 5);

        assertEq(token.balanceOf(tester), 5);
        assertEq(token.numMinted(tester), 5);

        for (uint256 i; i < 5; ++i) assertEq(token.ownerOf(i + 1), address(token));
        for (uint256 i; i < 5; ++i) assertEq(token.trueOwnerOf(i + 1), tester);

        uint256[] memory ids = 1.range(1 + 5);

        token.unlockFrom(tester, ids);

        for (uint256 i; i < 5; ++i) assertEq(token.ownerOf(i + 1), tester);
        for (uint256 i; i < 5; ++i) assertEq(token.trueOwnerOf(i + 1), tester);
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
        token.mint(alice, 1);

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

    /* ------------- fuzz ------------- */

    function testFuzz_mint(
        uint256 quantityA,
        uint256 quantityT,
        uint256 quantityB
    ) public {
        quantityT = 1 + (quantityT % 100);
        quantityA = 1 + (quantityA % 100);
        quantityB = 1 + (quantityB % 100);

        token.mint(alice, quantityA);
        token.mint(tester, quantityT);
        token.mint(bob, quantityB);

        for (uint256 i; i < quantityA; ++i) assertEq(token.ownerOf(1 + i), alice);
        for (uint256 i; i < quantityT; ++i) assertEq(token.ownerOf(1 + quantityA + i), tester);
        for (uint256 i; i < quantityB; ++i) assertEq(token.ownerOf(1 + quantityA + quantityT + i), bob);

        assertEq(token.balanceOf(tester), quantityT);
        assertEq(token.numMinted(tester), quantityT);
    }

    function testFuzz_lock(
        uint256 quantityA,
        uint256 quantityT,
        uint256 quantityB,
        uint256 quantityL,
        uint256 rand
    ) public {
        quantityT = 1 + (quantityT % 100);
        quantityA = 1 + (quantityA % 100);
        quantityB = 1 + (quantityB % 100);
        quantityL = 0 + (quantityL % quantityT);

        token.mint(alice, quantityA);
        token.mint(tester, quantityT);
        token.mint(bob, quantityB);

        uint256[] memory ids = (1 + quantityA).range(quantityA + quantityT + 1);
        uint256[] memory lockIds = ids.randomSubset(quantityL, rand);

        token.lockFrom(tester, lockIds);

        for (uint256 i; i < quantityT; ++i) {
            assertEq(token.ownerOf(ids[i]), lockIds.includes(ids[i]) ? address(token) : tester);
            assertEq(token.trueOwnerOf(ids[i]), tester);
        }

        token.unlockFrom(tester, lockIds);

        for (uint256 i; i < quantityA; ++i) assertEq(token.ownerOf(1 + i), alice);
        for (uint256 i; i < quantityT; ++i) assertEq(token.ownerOf(1 + quantityA), tester);
        for (uint256 i; i < quantityB; ++i) assertEq(token.ownerOf(1 + quantityA + quantityT + i), bob);

        assertEq(token.balanceOf(tester), quantityT);
    }

    function testFuzz_mintAndLock(
        uint256 quantityT,
        uint256 quantityA,
        uint256 quantityB,
        uint256 quantityL,
        uint256 rand
    ) public {
        quantityT = 1 + (quantityT % 100);
        quantityA = 1 + (quantityA % 100);
        quantityB = 1 + (quantityB % 100);
        quantityL = 0 + (quantityL % quantityT);

        token.mint(alice, quantityA);
        token.mintAndLock(tester, quantityT);
        token.mint(bob, quantityB);

        uint256[] memory ids = (1 + quantityA).range(quantityA + quantityT + 1);
        uint256[] memory unlockIds = ids.randomSubset(quantityL, rand);

        token.unlockFrom(tester, unlockIds);

        for (uint256 i; i < quantityT; ++i) {
            assertEq(token.ownerOf(ids[i]), unlockIds.includes(ids[i]) ? tester : address(token));
            assertEq(token.trueOwnerOf(ids[i]), tester);
        }

        token.lockFrom(tester, unlockIds);

        for (uint256 i; i < quantityA; ++i) assertEq(token.ownerOf(1 + i), alice);
        for (uint256 i; i < quantityT; ++i) assertEq(token.ownerOf(1 + quantityA), address(token));
        for (uint256 i; i < quantityT; ++i) assertEq(token.trueOwnerOf(1 + quantityA), tester);
        for (uint256 i; i < quantityB; ++i) assertEq(token.ownerOf(1 + quantityA + quantityT + i), bob);

        assertEq(token.balanceOf(tester), quantityT);
    }

    function testFuzz_transferFrom(
        uint256 quantityT,
        uint256 quantityA,
        uint256 quantityB,
        uint256 n,
        uint256 rand
    ) public {
        quantityT = 1 + (quantityT % 100);
        quantityA = 1 + (quantityA % 100);
        quantityB = 1 + (quantityB % 100);
        n = 1 + (n % 100);

        uint256 sum = quantityT + quantityA + quantityB;

        token.mint(alice, quantityA);
        token.mint(bob, quantityB);
        token.mint(tester, quantityT);

        address[] memory owners = new address[](sum);

        for (uint256 i; i < quantityA; ++i) owners[i] = alice;
        for (uint256 i; i < quantityB; ++i) owners[quantityA + i] = bob;
        for (uint256 i; i < quantityT; ++i) owners[quantityA + quantityB + i] = tester;

        for (uint256 i; i < n; ++i) {
            uint256 randId = uint256(keccak256(abi.encode(rand, i))) % sum;
            address newOwner = address(uint160(uint256(keccak256(abi.encode(rand, i)))));

            address oldOwner = owners[randId];

            vm.prank(oldOwner);
            token.transferFrom(oldOwner, newOwner, 1 + randId);

            owners[randId] = newOwner;
        }
    }
}
