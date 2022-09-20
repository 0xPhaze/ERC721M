// // SPDX-License-Identifier: MIT
// pragma solidity ^0.8.0;

// import "./mocks/MockERC721M.sol";
// import {ERC1967Proxy} from "UDS/proxy/ERC1967Proxy.sol";

// import {futils, random} from "futils/futils.sol";

// import "forge-std/Test.sol";

// contract TestERC721M is Test {
//     using futils for *;

//     address alice = address(0xbabe);
//     address bob = address(0xb0b);
//     address eve = address(0xefe);
//     address self = address(this);

//     MockERC721M token;

//     function setUp() public {
//         address logic = address(new MockERC721M("Token", "TKN"));
//         token = MockERC721M(address(new ERC1967Proxy(logic, "")));

//         vm.roll(123);
//         skip(456);
//     }

//     function test_setUp() public {
//         assertEq(DIAMOND_STORAGE_ERC721M_LOCKABLE, keccak256("diamond.storage.erc721m.lockable"));
//     }

//     /* ------------- lock() ------------- */

//     function test_lockUnlock() public {
//         token.mint(self, 1);

//         uint256[] memory ids = [1].toMemory();

//         token.lockFrom(self, ids);

//         assertEq(token.aux(1), 0);
//         assertEq(token.ownerOf(1), address(token));
//         assertEq(token.lockStart(1), block.timestamp);
//         assertEq(token.trueOwnerOf(1), self);

//         assertEq(token.balanceOf(self), 1);
//         assertEq(token.numMinted(self), 1);

//         assertEq(token.getOwnedIds(self), ids);
//         assertEq(token.getLockedIds(self), ids);
//         assertEq(token.getUnlockedIds(self), new uint256[](0));

//         token.unlockFrom(self, ids);

//         assertEq(token.aux(1), 0);
//         assertEq(token.ownerOf(1), self);
//         assertEq(token.lockStart(1), block.timestamp);
//         assertEq(token.trueOwnerOf(1), self);

//         assertEq(token.balanceOf(self), 1);
//         assertEq(token.numMinted(self), 1);

//         assertEq(token.getOwnedIds(self), ids);
//         assertEq(token.getLockedIds(self), new uint256[](0));
//         assertEq(token.getUnlockedIds(self), ids);
//     }

//     function test_lockUnlock_revert() public {
//         token.mint(alice, 1);
//         token.mint(self, 1);

//         vm.expectRevert(CallerNotOwnerNorApproved.selector);
//         token.lockFrom(alice, [1].toMemory());

//         vm.expectRevert(IncorrectOwner.selector);
//         token.lockFrom(self, [1].toMemory());

//         vm.expectRevert(CallerNotOwnerNorApproved.selector);
//         token.lockFrom(alice, [1].toMemory());

//         vm.prank(alice);
//         token.lockFrom(alice, [1].toMemory());

//         vm.expectRevert(IncorrectOwner.selector);
//         token.unlockFrom(self, [1].toMemory());

//         vm.expectRevert(CallerNotOwnerNorApproved.selector);
//         token.unlockFrom(alice, [1].toMemory());

//         vm.expectRevert(IncorrectOwner.selector);
//         token.lockFrom(self, [2, 2].toMemory());

//         token.lockFrom(self, [2].toMemory());

//         vm.expectRevert(TokenIdUnlocked.selector);
//         token.unlockFrom(self, [2, 2].toMemory());
//     }

//     function test_mintAndlock() public {
//         token.mintAndLock(self, 5);

//         uint256[] memory ids = 1.range(1 + 5);

//         for (uint256 i; i < 5; ++i) assertEq(token.aux(i + 1), 0);
//         for (uint256 i; i < 5; ++i) assertEq(token.ownerOf(i + 1), address(token));
//         for (uint256 i; i < 5; ++i) assertEq(token.lockStart(i + 1), block.timestamp);
//         for (uint256 i; i < 5; ++i) assertEq(token.trueOwnerOf(i + 1), self);

//         assertEq(token.balanceOf(self), 5);
//         assertEq(token.numMinted(self), 5);

//         assertEq(token.getOwnedIds(self), ids);
//         assertEq(token.getLockedIds(self), ids);
//         assertEq(token.getUnlockedIds(self), new uint256[](0));

//         token.unlockFrom(self, ids);

//         for (uint256 i; i < 5; ++i) assertEq(token.aux(i + 1), 0);
//         for (uint256 i; i < 5; i++) assertEq(token.ownerOf(i + 1), self);
//         for (uint256 i; i < 5; ++i) assertEq(token.lockStart(i + 1), block.timestamp);
//         for (uint256 i; i < 5; ++i) assertEq(token.trueOwnerOf(i + 1), self);

//         assertEq(token.balanceOf(self), 5);
//         assertEq(token.numMinted(self), 5);

//         assertEq(token.getOwnedIds(self), ids);
//         assertEq(token.getLockedIds(self), new uint256[](0));
//         assertEq(token.getUnlockedIds(self), ids);
//     }

//     /* ------------- mint() ------------- */

//     function test_mint() public {
//         token.mint(self, 1);

//         uint256[] memory ids = [1].toMemory();

//         assertEq(token.aux(1), 0);
//         assertEq(token.ownerOf(1), self);
//         assertEq(token.lockStart(1), 0);

//         assertEq(token.balanceOf(self), 1);
//         assertEq(token.numMinted(self), 1);

//         assertEq(token.getOwnedIds(self), ids);
//         assertEq(token.getLockedIds(self), new uint256[](0));
//         assertEq(token.getUnlockedIds(self), ids);
//     }

//     function test_mintFive() public {
//         token.mint(self, 5);

//         uint256[] memory ids = 1.range(1 + 5);

//         for (uint256 i; i < 5; ++i) assertEq(token.aux(i + 1), 0);
//         for (uint256 i; i < 5; i++) assertEq(token.ownerOf(i + 1), self);
//         for (uint256 i; i < 5; ++i) assertEq(token.lockStart(i + 1), 0);
//         for (uint256 i; i < 5; ++i) assertEq(token.trueOwnerOf(i + 1), self);

//         assertEq(token.balanceOf(self), 5);
//         assertEq(token.numMinted(self), 5);

//         assertEq(token.getOwnedIds(self), ids);
//         assertEq(token.getLockedIds(self), new uint256[](0));
//         assertEq(token.getUnlockedIds(self), ids);
//     }

//     function test_mint_revert_MintToZeroAddress() public {
//         vm.expectRevert(MintToZeroAddress.selector);
//         token.mint(address(0), 1);
//     }

//     /* ------------- approve() ------------- */

//     function test_approve() public {
//         token.mint(self, 1);
//         token.approve(alice, 1);

//         assertEq(token.getApproved(1), alice);
//     }

//     function test_approve_revert_NonexistentToken() public {
//         vm.expectRevert(NonexistentToken.selector);
//         token.approve(alice, 1);
//     }

//     function test_approve_revert_CallerNotOwnerNorApproved() public {
//         token.mint(bob, 1);

//         vm.expectRevert(CallerNotOwnerNorApproved.selector);
//         token.approve(alice, 1);
//     }

//     function test_setApprovalForAll() public {
//         token.setApprovalForAll(alice, true);

//         assertTrue(token.isApprovedForAll(self, alice));
//     }

//     /* ------------- transfer() ------------- */

//     function test_transferFrom() public {
//         token.mint(bob, 1);

//         vm.prank(bob);
//         token.approve(self, 1);

//         token.transferFrom(bob, alice, 1);

//         uint256[] memory ids = [1].toMemory();

//         assertEq(token.ownerOf(1), alice);
//         assertEq(token.getApproved(1), address(0));

//         assertEq(token.balanceOf(bob), 0);
//         assertEq(token.balanceOf(alice), 1);

//         assertEq(token.numMinted(bob), 1);
//         assertEq(token.numMinted(alice), 0);

//         assertEq(token.getOwnedIds(bob), new uint256[](0));
//         assertEq(token.getLockedIds(bob), new uint256[](0));
//         assertEq(token.getUnlockedIds(bob), new uint256[](0));

//         assertEq(token.getOwnedIds(alice), ids);
//         assertEq(token.getLockedIds(alice), new uint256[](0));
//         assertEq(token.getUnlockedIds(alice), ids);

//         assertEq(token.aux(1), 0);
//         assertEq(token.ownerOf(1), alice);
//         assertEq(token.lockStart(1), 0);
//         assertEq(token.trueOwnerOf(1), alice);
//     }

//     function test_transferFromSelf() public {
//         token.mint(self, 1);

//         token.transferFrom(self, alice, 1);

//         uint256[] memory ids = [1].toMemory();

//         assertEq(token.ownerOf(1), alice);
//         assertEq(token.getApproved(1), address(0));

//         assertEq(token.balanceOf(self), 0);
//         assertEq(token.balanceOf(alice), 1);

//         assertEq(token.numMinted(self), 1);
//         assertEq(token.numMinted(alice), 0);

//         assertEq(token.getOwnedIds(self), new uint256[](0));
//         assertEq(token.getLockedIds(self), new uint256[](0));
//         assertEq(token.getUnlockedIds(self), new uint256[](0));

//         assertEq(token.getOwnedIds(alice), ids);
//         assertEq(token.getLockedIds(alice), new uint256[](0));
//         assertEq(token.getUnlockedIds(alice), ids);
//     }

//     function test_transferFromApproveAll() public {
//         token.mint(bob, 1);

//         vm.prank(bob);
//         token.setApprovalForAll(self, true);

//         token.transferFrom(bob, alice, 1);

//         uint256[] memory ids = [1].toMemory();

//         assertEq(token.ownerOf(1), alice);
//         assertEq(token.getApproved(1), address(0));

//         assertEq(token.balanceOf(bob), 0);
//         assertEq(token.balanceOf(alice), 1);

//         assertEq(token.numMinted(bob), 1);
//         assertEq(token.numMinted(alice), 0);

//         assertEq(token.getOwnedIds(bob), new uint256[](0));
//         assertEq(token.getLockedIds(bob), new uint256[](0));
//         assertEq(token.getUnlockedIds(bob), new uint256[](0));

//         assertEq(token.getOwnedIds(alice), ids);
//         assertEq(token.getLockedIds(alice), new uint256[](0));
//         assertEq(token.getUnlockedIds(alice), ids);
//     }

//     function test_transferFrom_revert_NonexistentToken() public {
//         vm.expectRevert(NonexistentToken.selector);
//         token.transferFrom(bob, alice, 1);
//     }

//     function test_transferFrom_revert_TransferFromIncorrectOwner() public {
//         token.mint(self, 1);

//         vm.prank(bob);
//         token.setApprovalForAll(self, true);

//         vm.expectRevert(TransferFromIncorrectOwner.selector);
//         token.transferFrom(bob, alice, 1);
//     }

//     function test_transferFrom_revert_TransferToZeroAddress() public {
//         token.mint(self, 1);

//         vm.expectRevert(TransferToZeroAddress.selector);
//         token.transferFrom(self, address(0), 1);
//     }

//     function test_transferFrom_revert_CallerNotOwnerNorApproved() public {
//         token.mint(bob, 1);

//         vm.expectRevert(CallerNotOwnerNorApproved.selector);
//         token.transferFrom(bob, alice, 1);
//     }

//     /* ------------- fuzz ------------- */

//     function test_mint(
//         uint256 quantityA,
//         uint256 quantityB,
//         uint256 quantityE
//     ) public {
//         quantityA = bound(quantityA, 1, 100);
//         quantityB = bound(quantityB, 1, 100);
//         quantityE = bound(quantityE, 1, 100);

//         token.mint(alice, quantityA);
//         token.mint(bob, quantityB);
//         token.mint(eve, quantityE);

//         for (uint256 i; i < quantityA; ++i) assertEq(token.ownerOf(1 + i), alice);
//         for (uint256 i; i < quantityB; ++i) assertEq(token.ownerOf(1 + quantityA + i), bob);
//         for (uint256 i; i < quantityE; ++i) assertEq(token.ownerOf(1 + quantityA + quantityB + i), eve);

//         assertEq(token.balanceOf(alice), quantityA);
//         assertEq(token.balanceOf(bob), quantityB);
//         assertEq(token.balanceOf(eve), quantityE);

//         assertEq(token.numMinted(alice), quantityA);
//         assertEq(token.numMinted(bob), quantityB);
//         assertEq(token.numMinted(eve), quantityE);

//         uint256[] memory idsAlice = (1).range(1 + quantityA);
//         uint256[] memory idsBob = (1 + quantityA).range(1 + quantityA + quantityB);
//         uint256[] memory idsEve = (1 + quantityA + quantityB).range(1 + quantityA + quantityB + quantityE);

//         assertEq(token.getOwnedIds(alice), idsAlice);
//         assertEq(token.getOwnedIds(bob), idsBob);
//         assertEq(token.getOwnedIds(eve), idsEve);

//         assertEq(token.getUnlockedIds(alice), idsAlice);
//         assertEq(token.getUnlockedIds(bob), idsBob);
//         assertEq(token.getUnlockedIds(eve), idsEve);

//         assertEq(token.getLockedIds(alice), new uint256[](0));
//         assertEq(token.getLockedIds(bob), new uint256[](0));
//         assertEq(token.getLockedIds(eve), new uint256[](0));

//         assertEq(token.totalSupply(), quantityA + quantityB + quantityE);
//     }

//     function test_lock(
//         uint256 quantityA,
//         uint256 quantityB,
//         uint256 quantityE,
//         uint256 quantityL,
//         uint256 seed
//     ) public {
//         random.seed(seed);

//         quantityA = bound(quantityA, 1, 100);
//         quantityB = bound(quantityB, 1, 100);
//         quantityE = bound(quantityE, 1, 100);
//         quantityL = bound(quantityL, 0, quantityB);

//         token.mint(alice, quantityA);
//         token.mint(bob, quantityB);
//         token.mint(eve, quantityE);

//         uint256[] memory idsAlice = (1).range(1 + quantityA);
//         uint256[] memory idsBob = (1 + quantityA).range(1 + quantityA + quantityB);
//         uint256[] memory idsEve = (1 + quantityA + quantityB).range(1 + quantityA + quantityB + quantityE);

//         // Lock all `ownedIds` from bob.
//         vm.prank(bob);
//         token.lockFrom(bob, idsBob);

//         assertEq(token.getOwnedIds(bob), idsBob);
//         assertEq(token.getLockedIds(bob), idsBob);
//         assertEq(token.getUnlockedIds(bob), new uint256[](0));

//         uint256[] memory unlockedIds = idsBob.randomSubset(quantityL).sort();
//         uint256[] memory lockedIds = idsBob.exclusion(unlockedIds);

//         // Unlock `unlockedIds`.
//         vm.prank(bob);
//         token.unlockFrom(bob, unlockedIds);

//         for (uint256 i; i < idsBob.length; ++i) assertEq(token.trueOwnerOf(1 + quantityA + i), bob);
//         for (uint256 i; i < lockedIds.length; ++i) assertEq(token.ownerOf(lockedIds[i]), address(token));
//         for (uint256 i; i < unlockedIds.length; ++i) assertEq(token.ownerOf(unlockedIds[i]), bob);

//         for (uint256 i; i < quantityA; ++i) assertEq(token.ownerOf(1 + i), alice);
//         for (uint256 i; i < quantityE; ++i) assertEq(token.ownerOf(1 + quantityA + quantityB + i), eve);
//         for (uint256 i; i < quantityA; ++i) assertEq(token.trueOwnerOf(1 + i), alice);
//         for (uint256 i; i < quantityE; ++i) assertEq(token.trueOwnerOf(1 + quantityA + quantityB + i), eve);

//         assertEq(token.getOwnedIds(bob), idsBob);
//         assertEq(token.getLockedIds(bob), lockedIds);
//         assertEq(token.getUnlockedIds(bob), unlockedIds);

//         // Unlock remaining `lockedIds`.
//         vm.prank(bob);
//         token.unlockFrom(bob, lockedIds);

//         for (uint256 i; i < quantityA; ++i) assertEq(token.ownerOf(1 + i), alice);
//         for (uint256 i; i < quantityB; ++i) assertEq(token.ownerOf(1 + quantityA + i), bob);
//         for (uint256 i; i < quantityE; ++i) assertEq(token.ownerOf(1 + quantityA + quantityB + i), eve);

//         for (uint256 i; i < quantityA; ++i) assertEq(token.trueOwnerOf(1 + i), alice);
//         for (uint256 i; i < quantityB; ++i) assertEq(token.trueOwnerOf(1 + quantityA + i), bob);
//         for (uint256 i; i < quantityE; ++i) assertEq(token.trueOwnerOf(1 + quantityA + quantityB + i), eve);

//         assertEq(token.balanceOf(alice), quantityA);
//         assertEq(token.balanceOf(bob), quantityB);
//         assertEq(token.balanceOf(eve), quantityE);

//         assertEq(token.numMinted(alice), quantityA);
//         assertEq(token.numMinted(bob), quantityB);
//         assertEq(token.numMinted(eve), quantityE);

//         assertEq(token.getOwnedIds(alice), idsAlice);
//         assertEq(token.getOwnedIds(bob), idsBob);
//         assertEq(token.getOwnedIds(eve), idsEve);

//         assertEq(token.getUnlockedIds(alice), idsAlice);
//         assertEq(token.getUnlockedIds(bob), idsBob);
//         assertEq(token.getUnlockedIds(eve), idsEve);

//         assertEq(token.getLockedIds(alice), new uint256[](0));
//         assertEq(token.getLockedIds(bob), new uint256[](0));
//         assertEq(token.getLockedIds(eve), new uint256[](0));

//         assertEq(token.totalSupply(), quantityA + quantityB + quantityE);
//     }

//     function test_mintAndLock(
//         uint256 quantityA,
//         uint256 quantityB,
//         uint256 quantityE,
//         uint256 quantityL,
//         uint256 seed
//     ) public {
//         random.seed(seed);

//         quantityA = bound(quantityA, 1, 100);
//         quantityB = bound(quantityB, 1, 100);
//         quantityE = bound(quantityE, 1, 100);
//         quantityL = bound(quantityL, 0, quantityB);

//         token.mint(alice, quantityA);
//         token.mintAndLock(bob, quantityB);
//         token.mint(eve, quantityE);

//         uint256[] memory idsAlice = (1).range(1 + quantityA);
//         uint256[] memory idsBob = (1 + quantityA).range(1 + quantityA + quantityB);
//         uint256[] memory idsEve = (1 + quantityA + quantityB).range(1 + quantityA + quantityB + quantityE);

//         assertEq(token.getOwnedIds(bob), idsBob);
//         assertEq(token.getLockedIds(bob), idsBob);
//         assertEq(token.getUnlockedIds(bob), new uint256[](0));

//         uint256[] memory unlockedIds = idsBob.randomSubset(quantityL).sort();
//         uint256[] memory lockedIds = idsBob.exclusion(unlockedIds);

//         // Unlock `unlockedIds`.
//         vm.prank(bob);
//         token.unlockFrom(bob, unlockedIds);

//         assertEq(token.getOwnedIds(bob), idsBob);
//         assertEq(token.getLockedIds(bob), lockedIds);
//         assertEq(token.getUnlockedIds(bob), unlockedIds);

//         for (uint256 i; i < idsBob.length; ++i) assertEq(token.trueOwnerOf(1 + quantityA + i), bob);
//         for (uint256 i; i < lockedIds.length; ++i) assertEq(token.ownerOf(lockedIds[i]), address(token));
//         for (uint256 i; i < unlockedIds.length; ++i) assertEq(token.ownerOf(unlockedIds[i]), bob);

//         for (uint256 i; i < quantityA; ++i) assertEq(token.ownerOf(1 + i), alice);
//         for (uint256 i; i < quantityE; ++i) assertEq(token.ownerOf(1 + quantityA + quantityB + i), eve);
//         for (uint256 i; i < quantityA; ++i) assertEq(token.trueOwnerOf(1 + i), alice);
//         for (uint256 i; i < quantityE; ++i) assertEq(token.trueOwnerOf(1 + quantityA + quantityB + i), eve);

//         // Unlock remaining `lockedIds`.
//         vm.prank(bob);
//         token.unlockFrom(bob, lockedIds);

//         for (uint256 i; i < quantityA; ++i) assertEq(token.ownerOf(1 + i), alice);
//         for (uint256 i; i < quantityB; ++i) assertEq(token.ownerOf(1 + quantityA + i), bob);
//         for (uint256 i; i < quantityE; ++i) assertEq(token.ownerOf(1 + quantityA + quantityB + i), eve);

//         for (uint256 i; i < quantityA; ++i) assertEq(token.trueOwnerOf(1 + i), alice);
//         for (uint256 i; i < quantityB; ++i) assertEq(token.trueOwnerOf(1 + quantityA + i), bob);
//         for (uint256 i; i < quantityE; ++i) assertEq(token.trueOwnerOf(1 + quantityA + quantityB + i), eve);

//         assertEq(token.balanceOf(alice), quantityA);
//         assertEq(token.balanceOf(bob), quantityB);
//         assertEq(token.balanceOf(eve), quantityE);

//         assertEq(token.numMinted(alice), quantityA);
//         assertEq(token.numMinted(bob), quantityB);
//         assertEq(token.numMinted(eve), quantityE);

//         assertEq(token.getOwnedIds(alice), idsAlice);
//         assertEq(token.getOwnedIds(bob), idsBob);
//         assertEq(token.getOwnedIds(eve), idsEve);

//         assertEq(token.getUnlockedIds(alice), idsAlice);
//         assertEq(token.getUnlockedIds(bob), idsBob);
//         assertEq(token.getUnlockedIds(eve), idsEve);

//         assertEq(token.getLockedIds(alice), new uint256[](0));
//         assertEq(token.getLockedIds(bob), new uint256[](0));
//         assertEq(token.getLockedIds(eve), new uint256[](0));

//         assertEq(token.totalSupply(), quantityA + quantityB + quantityE);
//     }

//     function test_transferFrom(
//         uint256 quantityA,
//         uint256 quantityB,
//         uint256 quantityE,
//         uint256 quantityL,
//         uint256 n,
//         uint256 seed
//     ) public {
//         random.seed(seed);

//         n = bound(n, 1, 100);

//         test_mintAndLock(quantityA, quantityB, quantityE, quantityL, seed);

//         quantityA = bound(quantityA, 1, 100);
//         quantityB = bound(quantityB, 1, 100);
//         quantityE = bound(quantityE, 1, 100);

//         uint256 sum = quantityE + quantityA + quantityB;

//         address[] memory owners = new address[](sum);

//         for (uint256 i; i < quantityA; ++i) owners[i] = alice;
//         for (uint256 i; i < quantityB; ++i) owners[quantityA + i] = bob;
//         for (uint256 i; i < quantityE; ++i) owners[quantityA + quantityB + i] = eve;

//         for (uint256 i; i < n; ++i) {
//             uint256 id = random.next(sum);

//             address oldOwner = owners[id];
//             address newOwner = random.nextAddress();

//             vm.prank(oldOwner);
//             token.transferFrom(oldOwner, newOwner, 1 + id);

//             owners[id] = newOwner;

//             uint256[] memory foundIds = owners.filterIndices(newOwner);

//             for (uint256 j; j < foundIds.length; j++) ++foundIds[j];

//             assertEq(token.getOwnedIds(newOwner), foundIds);
//             assertEq(token.getLockedIds(newOwner), new uint256[](0));
//             assertEq(token.getUnlockedIds(newOwner), foundIds);
//         }
//     }
// }
