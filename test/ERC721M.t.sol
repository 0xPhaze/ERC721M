// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./mocks/MockERC721M.sol";
import {ERC1967Proxy} from "UDS/proxy/ERC1967Proxy.sol";

import {futils, random} from "futils/futils.sol";

import "forge-std/Test.sol";

contract TestERC721M is Test {
    using futils for *;

    address alice = address(0xbabe);
    address bob = address(0xb0b);
    address eve = address(0xefe);
    address self = address(this);

    MockERC721M token;

    uint48 aux;
    uint48 auxA;
    uint48 auxB;
    uint48 auxE;

    function setUp() public {
        address logic = address(new MockERC721M("Token", "TKN"));
        token = MockERC721M(address(new ERC1967Proxy(logic, "")));

        vm.roll(123);
        skip(456);

        aux = uint48(uint256(keccak256("aux")));
        auxA = uint48(uint256(keccak256("auxA")));
        auxB = uint48(uint256(keccak256("auxB")));
        auxE = uint48(uint256(keccak256("auxE")));
    }

    function test_setUp() public {
        assertEq(DIAMOND_STORAGE_ERC721M_LOCKABLE, keccak256("diamond.storage.erc721m.lockable"));
    }

    /* ------------- helper ------------- */

    function assertIdsOwned(
        address owner,
        uint256[] memory ids,
        uint256 lockStart,
        uint256 dataAux
    ) internal {
        uint256 length = ids.length;

        for (uint256 i; i < length; ++i) {
            assertEq(token.getAux(ids[i]), dataAux);
            assertEq(token.trueOwnerOf(ids[i]), owner);
            assertEq(token.getLockStart(ids[i]), lockStart);
        }

        assertEq(token.balanceOf(owner), length);
        assertEq(token.getOwnedIds(owner), ids);
    }

    function assertIdsLocked(
        address owner,
        uint256[] memory ids,
        uint256 lockStart,
        uint256 dataAux
    ) internal {
        uint256 length = ids.length;

        for (uint256 i; i < length; ++i) {
            assertEq(token.getAux(ids[i]), dataAux);
            assertEq(token.ownerOf(ids[i]), address(token));
            assertEq(token.trueOwnerOf(ids[i]), owner);
            assertEq(token.getLockStart(ids[i]), lockStart);
        }

        assertEq(token.numLocked(owner), ids.length);
        assertEq(token.getLockedIds(owner), ids);
        assertEq(token.getLockStart(owner), lockStart);
        assertTrue(ids.isSubset(token.getOwnedIds(owner)));
    }

    function assertIdsUnlocked(
        address owner,
        uint256[] memory ids,
        uint256 lockStart,
        uint256 dataAux
    ) internal {
        uint256 length = ids.length;

        for (uint256 i; i < length; ++i) {
            assertEq(token.getAux(ids[i]), dataAux);
            assertEq(token.ownerOf(ids[i]), owner);
            assertEq(token.trueOwnerOf(ids[i]), owner);
            assertEq(token.getLockStart(ids[i]), lockStart);
        }

        assertEq(token.numLocked(owner), token.balanceOf(owner) - ids.length);
        assertEq(token.getLockStart(owner), lockStart);
        assertEq(token.getUnlockedIds(owner), ids);
        assertTrue(ids.isSubset(token.getOwnedIds(owner)));
    }

    /* ------------- mint() ------------- */

    function test_mint() public {
        token.mint(self, 1);

        uint256[] memory ids = [1].toMemory();

        assertIdsOwned(self, ids, 0, 0);

        assertEq(token.numMinted(self), 1);
        assertEq(token.getLockedIds(self), new uint256[](0));
        assertEq(token.getUnlockedIds(self), ids);
    }

    function test_mintWithAux() public {
        token.mintWithAux(self, 1, aux);

        uint256[] memory ids = [1].toMemory();

        assertIdsOwned(self, ids, 0, aux);

        assertEq(token.numMinted(self), 1);
        assertEq(token.getLockedIds(self), new uint256[](0));
        assertEq(token.getUnlockedIds(self), ids);
    }

    function test_mintFive() public {
        token.mint(self, 5);

        uint256[] memory ids = 1.range(1 + 5);

        assertIdsOwned(self, ids, 0, 0);

        assertEq(token.numMinted(self), 5);
        assertEq(token.getLockedIds(self), new uint256[](0));
        assertEq(token.getUnlockedIds(self), ids);
    }

    function test_mintFiveWithAux() public {
        token.mintWithAux(self, 5, aux);

        uint256[] memory ids = 1.range(1 + 5);

        assertIdsOwned(self, ids, 0, aux);

        assertEq(token.numMinted(self), 5);
        assertEq(token.getLockedIds(self), new uint256[](0));
        assertEq(token.getUnlockedIds(self), ids);
    }

    function test_mintAndLock() public {
        token.mintAndLock(self, 5);

        uint256[] memory ids = 1.range(1 + 5);

        assertEq(token.numMinted(self), 5);

        assertIdsOwned(self, ids, block.timestamp, 0);
        assertIdsLocked(self, ids, block.timestamp, 0);
        assertIdsUnlocked(self, new uint256[](0), block.timestamp, 0);

        token.unlockFrom(self, ids);

        assertIdsOwned(self, ids, block.timestamp, 0);
        assertIdsLocked(self, new uint256[](0), block.timestamp, 0);
        assertIdsUnlocked(self, ids, block.timestamp, 0);
    }

    function test_mintAndLockWithAux() public {
        token.mintAndLockWithAux(self, 5, aux);

        uint256[] memory ids = 1.range(1 + 5);

        assertEq(token.numMinted(self), 5);

        assertIdsOwned(self, ids, block.timestamp, aux);
        assertIdsLocked(self, ids, block.timestamp, aux);
        assertIdsUnlocked(self, new uint256[](0), block.timestamp, 0);

        token.unlockFrom(self, ids);

        assertIdsOwned(self, ids, block.timestamp, aux);
        assertIdsLocked(self, new uint256[](0), block.timestamp, 0);
        assertIdsUnlocked(self, ids, block.timestamp, aux);
    }

    function test_mint_revert_MintToZeroAddress() public {
        vm.expectRevert(MintToZeroAddress.selector);
        token.mint(address(0), 1);
    }

    /* ------------- approve() ------------- */

    function test_approve() public {
        token.mint(self, 1);
        token.approve(alice, 1);

        assertEq(token.getApproved(1), alice);
    }

    function test_approve_revert_NonexistentToken() public {
        vm.expectRevert(NonexistentToken.selector);
        token.approve(alice, 1);
    }

    function test_approve_revert_CallerNotOwnerNorApproved() public {
        token.mint(bob, 1);

        vm.expectRevert(CallerNotOwnerNorApproved.selector);
        token.approve(alice, 1);
    }

    function test_setApprovalForAll() public {
        token.setApprovalForAll(alice, true);

        assertTrue(token.isApprovedForAll(self, alice));
    }

    /* ------------- transfer() ------------- */

    function test_transferFrom() public {
        token.mint(bob, 1);

        vm.prank(bob);
        token.approve(self, 1);

        token.transferFrom(bob, alice, 1);

        uint256[] memory ids = [1].toMemory();

        assertIdsOwned(alice, ids, 0, 0);

        assertEq(token.numMinted(alice), 0);
        assertEq(token.getLockedIds(alice), new uint256[](0));
        assertEq(token.getUnlockedIds(alice), ids);

        assertIdsOwned(bob, new uint256[](0), 0, 0);

        assertEq(token.numMinted(bob), 1);
        assertEq(token.getLockedIds(bob), new uint256[](0));
        assertEq(token.getUnlockedIds(bob), new uint256[](0));
    }

    function test_transferFromSelf() public {
        token.mint(self, 1);

        token.transferFrom(self, alice, 1);

        uint256[] memory ids = [1].toMemory();

        assertIdsOwned(alice, ids, 0, 0);

        assertEq(token.numMinted(alice), 0);
        assertEq(token.getLockedIds(alice), new uint256[](0));
        assertEq(token.getUnlockedIds(alice), ids);

        assertIdsOwned(self, new uint256[](0), 0, 0);

        assertEq(token.numMinted(self), 1);
        assertEq(token.getLockedIds(self), new uint256[](0));
        assertEq(token.getUnlockedIds(self), new uint256[](0));
    }

    function test_transferFromApproveAll() public {
        token.mint(bob, 1);

        vm.prank(bob);
        token.setApprovalForAll(self, true);

        token.transferFrom(bob, alice, 1);

        uint256[] memory ids = [1].toMemory();

        assertIdsOwned(alice, ids, 0, 0);

        assertEq(token.numMinted(alice), 0);
        assertEq(token.getLockedIds(alice), new uint256[](0));
        assertEq(token.getUnlockedIds(alice), ids);

        assertIdsOwned(bob, new uint256[](0), 0, 0);

        assertEq(token.numMinted(bob), 1);
        assertEq(token.getLockedIds(bob), new uint256[](0));
        assertEq(token.getUnlockedIds(bob), new uint256[](0));
    }

    function test_transferFrom_revert_NonexistentToken() public {
        vm.expectRevert(NonexistentToken.selector);
        token.transferFrom(bob, alice, 1);
    }

    function test_transferFrom_revert_TransferFromIncorrectOwner() public {
        token.mint(self, 1);

        vm.prank(bob);
        token.setApprovalForAll(self, true);

        vm.expectRevert(TransferFromIncorrectOwner.selector);
        token.transferFrom(bob, alice, 1);
    }

    function test_transferFrom_revert_TransferToZeroAddress() public {
        token.mint(self, 1);

        vm.expectRevert(TransferToZeroAddress.selector);
        token.transferFrom(self, address(0), 1);
    }

    function test_transferFrom_revert_CallerNotOwnerNorApproved() public {
        token.mint(bob, 1);

        vm.expectRevert(CallerNotOwnerNorApproved.selector);
        token.transferFrom(bob, alice, 1);
    }

    /* ------------- lock() ------------- */

    function test_lockUnlock() public {
        token.mint(self, 1);

        uint256[] memory ids = [1].toMemory();

        token.lockFrom(self, ids);

        assertIdsLocked(self, ids, block.timestamp, 0);

        assertEq(token.numMinted(self), 1);
        assertEq(token.getOwnedIds(self), ids);
        assertEq(token.getUnlockedIds(self), new uint256[](0));

        token.unlockFrom(self, ids);

        assertIdsOwned(self, ids, block.timestamp, 0);

        assertEq(token.numMinted(self), 1);
        assertEq(token.getLockedIds(self), new uint256[](0));
        assertEq(token.getUnlockedIds(self), ids);
    }

    function test_lockUnlock_revert() public {
        token.mint(alice, 1);
        token.mint(self, 1);

        vm.expectRevert(CallerNotOwnerNorApproved.selector);
        token.lockFrom(alice, [1].toMemory());

        vm.expectRevert(IncorrectOwner.selector);
        token.lockFrom(self, [1].toMemory());

        vm.expectRevert(CallerNotOwnerNorApproved.selector);
        token.lockFrom(alice, [1].toMemory());

        vm.prank(alice);
        token.lockFrom(alice, [1].toMemory());

        vm.expectRevert(IncorrectOwner.selector);
        token.unlockFrom(self, [1].toMemory());

        vm.expectRevert(CallerNotOwnerNorApproved.selector);
        token.unlockFrom(alice, [1].toMemory());

        vm.expectRevert(IncorrectOwner.selector);
        token.lockFrom(self, [2, 2].toMemory());

        token.lockFrom(self, [2].toMemory());

        vm.expectRevert(TokenIdUnlocked.selector);
        token.unlockFrom(self, [2, 2].toMemory());
    }

    /* ------------- fuzz ------------- */

    function test_mint(
        uint256 quantityA,
        uint256 quantityB,
        uint256 quantityE
    ) public {
        quantityA = bound(quantityA, 1, 100);
        quantityB = bound(quantityB, 1, 100);
        quantityE = bound(quantityE, 1, 100);

        token.mintWithAux(alice, quantityA, auxA);
        token.mintWithAux(bob, quantityB, auxB);
        token.mintWithAux(eve, quantityE, auxE);

        uint256[] memory idsAlice = (1).range(1 + quantityA);
        uint256[] memory idsBob = (1 + quantityA).range(1 + quantityA + quantityB);
        uint256[] memory idsEve = (1 + quantityA + quantityB).range(1 + quantityA + quantityB + quantityE);

        assertEq(token.numMinted(alice), quantityA);
        assertEq(token.numMinted(bob), quantityB);
        assertEq(token.numMinted(eve), quantityE);

        assertIdsOwned(alice, idsAlice, 0, auxA);
        assertIdsOwned(bob, idsBob, 0, auxB);
        assertIdsOwned(eve, idsEve, 0, auxE);

        assertEq(token.totalSupply(), quantityA + quantityB + quantityE);
    }

    function test_lock(
        uint256 quantityA,
        uint256 quantityB,
        uint256 quantityE,
        uint256 quantityL,
        uint256 seed
    ) public {
        random.seed(seed);

        quantityA = bound(quantityA, 1, 100);
        quantityB = bound(quantityB, 1, 100);
        quantityE = bound(quantityE, 1, 100);
        quantityL = bound(quantityL, 0, quantityB);

        token.mintWithAux(alice, quantityA, auxA);
        token.mintWithAux(bob, quantityB, auxB);
        token.mintWithAux(eve, quantityE, auxE);

        uint256[] memory idsAlice = (1).range(1 + quantityA);
        uint256[] memory idsBob = (1 + quantityA).range(1 + quantityA + quantityB);
        uint256[] memory idsEve = (1 + quantityA + quantityB).range(1 + quantityA + quantityB + quantityE);

        // Lock all `ownedIds` from bob.
        vm.prank(bob);
        token.lockFrom(bob, idsBob);

        assertIdsUnlocked(bob, new uint256[](0), block.timestamp, auxB);
        assertIdsLocked(bob, idsBob, block.timestamp, auxB);

        assertIdsOwned(alice, idsAlice, 0, auxA);
        assertIdsOwned(eve, idsEve, 0, auxE);

        assertEq(token.totalNumLocked(), quantityB);

        // Unlock `unlockedIds`.
        uint256[] memory unlockedIds = idsBob.randomSubset(quantityL).sort();
        uint256[] memory lockedIds = idsBob.exclusion(unlockedIds);

        vm.prank(bob);
        token.unlockFrom(bob, unlockedIds);

        assertIdsUnlocked(bob, unlockedIds, block.timestamp, auxB);
        assertIdsLocked(bob, lockedIds, block.timestamp, auxB);

        assertIdsOwned(alice, idsAlice, 0, auxA);
        assertIdsOwned(eve, idsEve, 0, auxE);

        assertEq(token.totalNumLocked(), lockedIds.length);

        // Unlock remaining `lockedIds`.
        vm.prank(bob);
        token.unlockFrom(bob, lockedIds);

        assertIdsUnlocked(bob, idsBob, block.timestamp, auxB);
        assertIdsLocked(bob, new uint256[](0), block.timestamp, auxB);

        assertIdsOwned(alice, idsAlice, 0, auxA);
        assertIdsOwned(eve, idsEve, 0, auxE);

        assertEq(token.totalSupply(), quantityA + quantityB + quantityE);
        assertEq(token.totalNumLocked(), 0);
    }

    function test_mintAndLock(
        uint256 quantityA,
        uint256 quantityB,
        uint256 quantityE,
        uint256 quantityL,
        uint256 seed
    ) public {
        random.seed(seed);

        quantityA = bound(quantityA, 1, 100);
        quantityB = bound(quantityB, 1, 100);
        quantityE = bound(quantityE, 1, 100);
        quantityL = bound(quantityL, 0, quantityB);

        token.mintWithAux(alice, quantityA, auxA);
        token.mintAndLockWithAux(bob, quantityB, auxB);
        token.mintWithAux(eve, quantityE, auxE);

        uint256[] memory idsAlice = (1).range(1 + quantityA);
        uint256[] memory idsBob = (1 + quantityA).range(1 + quantityA + quantityB);
        uint256[] memory idsEve = (1 + quantityA + quantityB).range(1 + quantityA + quantityB + quantityE);

        assertIdsUnlocked(bob, new uint256[](0), block.timestamp, auxB);
        assertIdsLocked(bob, idsBob, block.timestamp, auxB);

        assertIdsOwned(alice, idsAlice, 0, auxA);
        assertIdsOwned(eve, idsEve, 0, auxE);

        // Unlock `unlockedIds`.
        uint256[] memory unlockedIds = idsBob.randomSubset(quantityL).sort();
        uint256[] memory lockedIds = idsBob.exclusion(unlockedIds);

        vm.prank(bob);
        token.unlockFrom(bob, unlockedIds);

        assertIdsUnlocked(bob, unlockedIds, block.timestamp, auxB);
        assertIdsLocked(bob, lockedIds, block.timestamp, auxB);

        assertIdsOwned(alice, idsAlice, 0, auxA);
        assertIdsOwned(eve, idsEve, 0, auxE);

        assertEq(token.totalNumLocked(), lockedIds.length);

        // Unlock remaining `lockedIds`.
        vm.prank(bob);
        token.unlockFrom(bob, lockedIds);

        assertIdsUnlocked(bob, idsBob, block.timestamp, auxB);
        assertIdsLocked(bob, new uint256[](0), block.timestamp, auxB);

        assertIdsOwned(alice, idsAlice, 0, auxA);
        assertIdsOwned(eve, idsEve, 0, auxE);

        assertEq(token.totalSupply(), quantityA + quantityB + quantityE);
    }

    function test_transferFrom(
        uint256 quantityA,
        uint256 quantityB,
        uint256 quantityE,
        uint256 quantityL,
        uint256 n,
        uint256 seed
    ) public {
        random.seed(seed);

        n = bound(n, 1, 100);

        test_mintAndLock(quantityA, quantityB, quantityE, quantityL, seed);

        quantityA = bound(quantityA, 1, 100);
        quantityB = bound(quantityB, 1, 100);
        quantityE = bound(quantityE, 1, 100);

        uint256 totalSupply = quantityE + quantityA + quantityB;

        uint48[] memory auxData = new uint48[](totalSupply);
        address[] memory owners = new address[](totalSupply);

        for (uint256 i; i < quantityA; ++i) owners[i] = alice;
        for (uint256 i; i < quantityB; ++i) owners[quantityA + i] = bob;
        for (uint256 i; i < quantityE; ++i) owners[quantityA + quantityB + i] = eve;

        for (uint256 i; i < quantityA; ++i) auxData[i] = auxA;
        for (uint256 i; i < quantityB; ++i) auxData[quantityA + i] = auxB;
        for (uint256 i; i < quantityE; ++i) auxData[quantityA + quantityB + i] = auxE;

        for (uint256 i; i < n; ++i) {
            uint256 id = random.next(totalSupply);
            uint48 randomAux = uint48(uint256(random.next(totalSupply)));

            address oldOwner = owners[id];
            address newOwner = random.nextAddress();

            vm.prank(oldOwner);
            token.transferFrom(oldOwner, newOwner, 1 + id);
            token.setAux(1 + id, randomAux);

            owners[id] = newOwner;
            auxData[id] = randomAux;

            uint256[] memory newOwnerIds = owners.filterIndices(newOwner);

            for (uint256 j; j < newOwnerIds.length; j++) ++newOwnerIds[j];

            assertEq(token.getOwnedIds(newOwner), newOwnerIds);
            assertEq(token.getLockedIds(newOwner), new uint256[](0));
            assertEq(token.getUnlockedIds(newOwner), newOwnerIds);
        }

        for (uint256 i; i < totalSupply; ++i) {
            assertEq(token.getAux(1 + i), auxData[i]);
        }
    }
}
