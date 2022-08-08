// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "forge-std/Test.sol";

import "./mocks/MockERC721M.sol";
import "f-utils/fUtils.sol";

contract ERC721MTest is Test {
    using fUtils for *;

    address alice = address(0xbabe);
    address bob = address(0xb0b);
    address tester = address(this);

    MockERC721M token;

    function setUp() public {
        token = new MockERC721M("Token", "TKN");
    }

    function test_setUp() public {
        assertEq(DIAMOND_STORAGE_ERC721M_LOCKABLE, keccak256("diamond.storage.erc721m.lockable"));
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

    function test_mint(
        uint256 quantityA,
        uint256 quantityT,
        uint256 quantityB
    ) public {
        quantityA = bound(quantityA, 1, 100);
        quantityB = bound(quantityB, 1, 100);
        quantityT = bound(quantityT, 1, 100);

        token.mint(alice, quantityA);
        token.mint(bob, quantityB);
        token.mint(tester, quantityT);

        for (uint256 i; i < quantityA; ++i) assertEq(token.ownerOf(1 + i), alice);
        for (uint256 i; i < quantityB; ++i) assertEq(token.ownerOf(1 + quantityA + i), bob);
        for (uint256 i; i < quantityT; ++i) assertEq(token.ownerOf(1 + quantityA + quantityB + i), tester);

        assertEq(token.balanceOf(bob), quantityB);
        assertEq(token.balanceOf(alice), quantityA);
        assertEq(token.balanceOf(tester), quantityT);

        assertEq(token.numMinted(bob), quantityB);
        assertEq(token.numMinted(alice), quantityA);
        assertEq(token.numMinted(tester), quantityT);
    }

    function test_lock(
        uint256 quantityA,
        uint256 quantityT,
        uint256 quantityB,
        uint256 quantityL,
        uint256 seed
    ) public {
        random.seed(seed);

        quantityA = bound(quantityA, 1, 100);
        quantityB = bound(quantityB, 1, 100);
        quantityT = bound(quantityT, 1, 100);

        token.mint(alice, quantityA);
        token.mintAndLock(bob, quantityB);
        token.mint(tester, quantityT);

        uint256[] memory ids = (1 + quantityA).range(quantityA + quantityB + 1);

        quantityL = bound(quantityL, 0, ids.length);

        uint256[] memory unlockIds = ids.randomSubset(quantityL);
        uint256[] memory lockedIds = ids.exclusion(unlockIds);

        vm.prank(bob);
        token.unlockFrom(bob, unlockIds);

        for (uint256 i; i < unlockIds.length; ++i) assertEq(token.ownerOf(unlockIds[i]), bob);
        for (uint256 i; i < lockedIds.length; ++i) assertEq(token.ownerOf(lockedIds[i]), address(token));

        vm.prank(bob);
        token.unlockFrom(bob, lockedIds);

        for (uint256 i; i < quantityA; ++i) assertEq(token.ownerOf(1 + i), alice);
        for (uint256 i; i < quantityB; ++i) assertEq(token.ownerOf(1 + quantityA + i), bob);
        for (uint256 i; i < quantityT; ++i) assertEq(token.ownerOf(1 + quantityA + quantityB + i), tester);

        assertEq(token.balanceOf(bob), quantityB);
    }

    function test_mintAndLock(
        uint256 quantityA,
        uint256 quantityB,
        uint256 quantityT,
        uint256 quantityL,
        uint256 seed
    ) public {
        random.seed(seed);

        quantityA = bound(quantityA, 1, 100);
        quantityB = bound(quantityB, 1, 100);
        quantityT = bound(quantityT, 1, 100);

        token.mint(alice, quantityA);
        token.mintAndLock(bob, quantityB);
        token.mint(tester, quantityT);

        uint256[] memory ids = (1 + quantityA).range(1 + quantityA + quantityB);

        quantityL = bound(quantityL, 0, ids.length);

        uint256[] memory unlockIds = ids.randomSubset(quantityL);
        uint256[] memory lockedIds = ids.exclusion(unlockIds);

        vm.prank(bob);
        token.unlockFrom(bob, unlockIds);

        for (uint256 i; i < unlockIds.length; ++i) assertEq(token.ownerOf(unlockIds[i]), bob);
        for (uint256 i; i < lockedIds.length; ++i) assertEq(token.ownerOf(lockedIds[i]), address(token));

        for (uint256 i; i < quantityA; ++i) assertEq(token.ownerOf(1 + i), alice);
        for (uint256 i; i < quantityB; ++i) assertEq(token.trueOwnerOf(1 + quantityA + i), bob);
        for (uint256 i; i < quantityT; ++i) assertEq(token.ownerOf(1 + quantityA + quantityB + i), tester);

        vm.prank(bob);
        token.unlockFrom(bob, lockedIds);

        for (uint256 i; i < quantityA; ++i) assertEq(token.ownerOf(1 + i), alice);
        for (uint256 i; i < quantityB; ++i) assertEq(token.ownerOf(1 + quantityA + i), bob);
        for (uint256 i; i < quantityT; ++i) assertEq(token.ownerOf(1 + quantityA + quantityB + i), tester);

        assertEq(token.balanceOf(bob), quantityB);
    }

    function test_transferFrom(
        uint256 quantityA,
        uint256 quantityB,
        uint256 quantityT,
        uint256 quantityL,
        uint256 n,
        uint256 seed
    ) public {
        random.seed(seed);

        n = bound(n, 1, 100);

        test_mintAndLock(quantityA, quantityB, quantityT, quantityL, seed);

        quantityA = bound(quantityA, 1, 100);
        quantityB = bound(quantityB, 1, 100);
        quantityT = bound(quantityT, 1, 100);

        uint256 sum = quantityT + quantityA + quantityB;

        address[] memory owners = new address[](sum);

        for (uint256 i; i < quantityA; ++i) owners[i] = alice;
        for (uint256 i; i < quantityB; ++i) owners[quantityA + i] = bob;
        for (uint256 i; i < quantityT; ++i) owners[quantityA + quantityB + i] = tester;

        for (uint256 i; i < n; ++i) {
            uint256 id = random.next(sum);

            address oldOwner = owners[id];
            address newOwner = random.nextAddress();

            vm.prank(oldOwner);
            token.transferFrom(oldOwner, newOwner, 1 + id);

            owners[id] = newOwner;
        }
    }
}
