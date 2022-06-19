// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

struct UserData {
    uint256 balance;
    uint256 numMinted;
    // uint256 numLocked;
}

library UserDataOps {
    function getUserData(uint256 userData) internal pure returns (UserData memory) {
        return
            UserData({
                balance: UserDataOps.balance(userData),
                numMinted: UserDataOps.numMinted(userData)
                // numLocked: UserDataOps.numLocked(userData)
            });
    }

    function balance(uint256 userData) internal pure returns (uint256) {
        return userData & 0xFFFFF;
    }

    function increaseBalance(uint256 userData, uint256 amount) internal pure returns (uint256) {
        unchecked {
            return userData + amount;
        }
    }

    function decreaseBalance(uint256 userData, uint256 amount) internal pure returns (uint256) {
        unchecked {
            return userData - amount;
        }
    }

    function numMinted(uint256 userData) internal pure returns (uint256) {
        return (userData >> 20) & 0xFFFFF;
    }

    function increaseNumMinted(uint256 userData, uint256 amount) internal pure returns (uint256) {
        unchecked {
            return userData + (amount << 20);
        }
    }

    function numLocked(uint256 userData) internal pure returns (uint256) {
        return (userData >> 120) & 0xFF;
    }

    function increaseNumLocked(uint256 userData, uint256 amount) internal pure returns (uint256) {
        unchecked {
            return userData + (amount << 120);
        }
    }

    function decreaseNumLocked(uint256 userData, uint256 amount) internal pure returns (uint256) {
        unchecked {
            return userData - (amount << 120);
        }
    }

    // function lockStart(uint256 userData) internal pure returns (uint256) {
    //     return (userData >> 40) & 0xFFFFFFFFFF;
    // }

    // function setLockStart(uint256 userData, uint256 timestamp) internal pure returns (uint256) {
    //     return (userData & 0xFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF0000000000FFFFFFFFFF) | (timestamp << 40);
    // }
}

// # ERC721M.sol
//
// tokenData layout:
// 0xcccccccccccccccccccccccbaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaa
// a [  0] (uint160): address #owner            (owner of token id)
// b [160] (bool): #nextTokenDataSet flag       (flag whether the data of next token id has already been set)
// b [161] (bool): #locked flag                 (flag whether id has been locked) Note: this carries over when calling 'ownerOf'
// b [162] (bool): #mintAndLock flag            (flag whether to carry over lock flag when calling tokenDataOf; used for mintAndLock and boost)
// c [168] (uint88): #aux                       (aux data)

struct TokenData {
    address owner;
    bool locked;
    bool mintAndLock;
    bool nextTokenDataSet;
    // uint256 aux;
}

library TokenDataOps {
    address constant warden = address(0xb0b);

    function getTokenData(uint256 tokenData) internal pure returns (TokenData memory) {
        return
            TokenData({
                owner: TokenDataOps.owner(tokenData),
                locked: TokenDataOps.locked(tokenData),
                mintAndLock: TokenDataOps.mintAndLock(tokenData),
                nextTokenDataSet: TokenDataOps.nextTokenDataSet(tokenData)
                // aux: TokenDataOps.aux(tokenData),
            });
    }

    function newTokenData(
        address owner_,
        uint256 lastTransfer_,
        bool lock_
    ) internal pure returns (uint256) {
        uint256 tokenData = (uint256(uint160(owner_)) | (lastTransfer_ << 160) | (uint256(1) << 168));
        return lock_ ? lock(setMintAndLocked(tokenData)) : tokenData;
    }

    /* ------------- owner: [0, 160) ------------- */

    function owner(uint256 tokenData) internal pure returns (address) {
        return (locked(tokenData)) ? warden : trueOwner(tokenData);
    }

    function setOwner(uint256 tokenData, address owner_) internal pure returns (uint256) {
        return (tokenData & 0xFFFFFFFFFFFFFFFFFFFFFFFF0000000000000000000000000000000000000000) | uint160(owner_);
    }

    function trueOwner(uint256 tokenData) internal pure returns (address) {
        return address(uint160(tokenData));
    }

    /* ------------- nextTokenDataSet: [160, 161) ------------- */

    function nextTokenDataSet(uint256 tokenData) internal pure returns (bool) {
        return ((tokenData >> 160) & uint256(1)) != 0;
    }

    function flagNextTokenDataSet(uint256 tokenData) internal pure returns (uint256) {
        return tokenData | (uint256(1) << 160); // nextTokenDatatSet flag (don't repeat the read/write)
    }

    /* ------------- locked: [161, 162) ------------- */

    function locked(uint256 tokenData) internal pure returns (bool) {
        return ((tokenData >> 161) & uint256(1)) != 0; // Note: this can carry over when calling 'ownerOf'
    }

    function lock(uint256 tokenData) internal pure returns (uint256) {
        return tokenData | (uint256(1) << 161);
    }

    function unlock(uint256 tokenData) internal pure returns (uint256) {
        return tokenData & ~(uint256(1) << 161);
    }

    /* ------------- mintAndLock: [162, 163) ------------- */

    function mintAndLock(uint256 tokenData) internal pure returns (bool) {
        return ((tokenData >> 162) & uint256(1)) != 0;
    }

    function setMintAndLocked(uint256 tokenData) internal pure returns (uint256) {
        return tokenData | (uint256(1) << 162);
    }

    function unsetMintAndLocked(uint256 tokenData) internal pure returns (uint256) {
        return tokenData & ~(uint256(1) << 162);
    }

    /* ------------- aux: [168, 256) ------------- */

    function aux(uint256 tokenData) internal pure returns (uint256) {
        return (tokenData >> 168) & 0xFFFFFFFFFFFFFFFFFFFFFF;
    }
}
