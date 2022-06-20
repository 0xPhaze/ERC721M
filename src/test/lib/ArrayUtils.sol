// SPDX-License-Identifier: MIT
pragma solidity ^0.8.12;

import "forge-std/console.sol";

/// @notice utils for array manipulation
/// @author phaze (https://github.com/0xPhaze)
library ArrayUtils {
    /* ------------- utils ------------- */

    function slice(
        uint256[] memory arr,
        uint256 from,
        uint256 to
    ) internal pure returns (uint256[] memory ret) {
        assert(from <= to);
        assert(to <= arr.length);

        uint256 n = to - from;
        ret = new uint256[](n);

        unchecked {
            for (uint256 i = 0; i < n; ++i) ret[i] = arr[from + i];
        }
    }

    function _slice(
        uint256[] memory arr,
        uint256 from,
        uint256 to
    ) internal pure returns (uint256[] memory ret) {
        assert(from <= to);
        assert(to <= arr.length);

        assembly {
            ret := add(arr, mul(0x20, from))
            mstore(ret, sub(to, from))
        }
    }

    function range(uint256 from, uint256 to) internal pure returns (uint256[] memory ret) {
        assert(from <= to);

        unchecked {
            ret = new uint256[](to - from);
            for (uint256 i; i < to - from; ++i) ret[i] = from + i;
        }
    }

    function copy(uint256[] memory arr) internal pure returns (uint256[] memory ret) {
        uint256 n = arr.length;
        ret = new uint256[](n);

        unchecked {
            for (uint256 i = 0; i < n; ++i) ret[i] = arr[i];
        }
    }

    function shuffle(uint256[] memory arr, uint256 rand) internal pure returns (uint256[] memory ret) {
        return _shuffle(copy(arr), rand);
    }

    function _shuffle(uint256[] memory arr, uint256 rand) internal pure returns (uint256[] memory ret) {
        ret = arr;

        uint256 n = ret.length;
        uint256 r = rand;
        uint256 c;

        unchecked {
            for (uint256 i; i < n; ++i) {
                c = i + (uint256(keccak256(abi.encode(r, i))) % (n - i));
                (ret[i], ret[c]) = (ret[c], ret[i]);
            }
        }
    }

    function shuffledRange(
        uint256 from,
        uint256 to,
        uint256 rand
    ) internal pure returns (uint256[] memory ret) {
        ret = new uint256[](to);

        uint256 r = rand;
        uint256 c;

        unchecked {
            for (uint256 i = 1; i < to; ++i) {
                c = uint256(keccak256(abi.encode(r, i))) % (i + 1);
                (ret[c], ret[i]) = (from + i, ret[c]);
            }
        }
    }

    function randomSubset(
        uint256[] memory arr,
        uint256 n,
        uint256 rand
    ) internal pure returns (uint256[] memory ret) {
        return _randomSubset(copy(arr), n, rand);
    }

    function _randomSubset(
        uint256[] memory arr,
        uint256 n,
        uint256 rand
    ) internal pure returns (uint256[] memory ret) {
        uint256 arrLength = arr.length;
        assert(n <= arrLength);

        ret = arr;

        uint256 r = rand;
        uint256 c;

        unchecked {
            for (uint256 i; i < n; ++i) {
                c = i + (uint256(keccak256(abi.encode(r, i))) % (arrLength - i));
                (ret[i], ret[c]) = (ret[c], ret[i]);
            }
        }
        ret = _slice(ret, 0, n);
    }

    // /// Optimized; reduces randomness to range [0,2^16)
    // function shuffledRangeOpt(
    //     uint256 from,
    //     uint256 to,
    //     uint256 rand
    // ) internal pure returns (uint256[] memory ret) {
    //     ret = new uint256[](to);

    //     uint256 r = rand;
    //     uint256 c;

    //     unchecked {
    //         for (uint256 i = 1; i < to; ++i) {
    //             uint256 slot = (i & 0xf) << 4;
    //             if (slot == 0 && i != 0) r = uint256(keccak256(abi.encode(r, i)));
    //             c = ((r >> slot) & 0xffff) % (i + 1);
    //             (ret[c], ret[i]) = (from + i, ret[c]);
    //         }
    //     }
    // }

    function extend(uint256[] memory arr, uint256 value) internal pure returns (uint256[] memory ret) {
        uint256 n = arr.length;
        ret = new uint256[](n + 1);
        for (uint256 i; i < n; ++i) ret[i] = arr[i];
        ret[n + 1] = value;
    }

    function includes(uint256[] memory arr, uint256 num) internal pure returns (bool) {
        for (uint256 i; i < arr.length; ++i) if (arr[i] == num) return true;
        return false;
    }

    /* ------------- address ------------- */

    function includes(address[] memory arr, address address_) internal pure returns (bool) {
        for (uint256 i; i < arr.length; ++i) if (arr[i] == address_) return true;
        return false;
    }

    /* ------------- uint8 ------------- */

    function toMemory32(uint8[1] memory arr) internal pure returns (uint32[] memory out) {
        unchecked {
            out = new uint32[](1);
            for (uint256 i; i < 1; ++i) out[i] = arr[i];
        }
    }

    function toMemory32(uint8[2] memory arr) internal pure returns (uint32[] memory out) {
        unchecked {
            out = new uint32[](2);
            for (uint256 i; i < 2; ++i) out[i] = arr[i];
        }
    }

    function toMemory32(uint8[3] memory arr) internal pure returns (uint32[] memory out) {
        unchecked {
            out = new uint32[](3);
            for (uint256 i; i < 3; ++i) out[i] = arr[i];
        }
    }

    function toMemory32(uint8[4] memory arr) internal pure returns (uint32[] memory out) {
        unchecked {
            out = new uint32[](4);
            for (uint256 i; i < 4; ++i) out[i] = arr[i];
        }
    }

    function toMemory32(uint8[5] memory arr) internal pure returns (uint32[] memory out) {
        unchecked {
            out = new uint32[](5);
            for (uint256 i; i < 5; ++i) out[i] = arr[i];
        }
    }

    function toMemory32(uint8[6] memory arr) internal pure returns (uint32[] memory out) {
        unchecked {
            out = new uint32[](6);
            for (uint256 i; i < 6; ++i) out[i] = arr[i];
        }
    }

    function toMemory32(uint8[7] memory arr) internal pure returns (uint32[] memory out) {
        unchecked {
            out = new uint32[](7);
            for (uint256 i; i < 7; ++i) out[i] = arr[i];
        }
    }

    function toMemory32(uint8[8] memory arr) internal pure returns (uint32[] memory out) {
        unchecked {
            out = new uint32[](8);
            for (uint256 i; i < 8; ++i) out[i] = arr[i];
        }
    }

    function toMemory32(uint8[9] memory arr) internal pure returns (uint32[] memory out) {
        unchecked {
            out = new uint32[](9);
            for (uint256 i; i < 9; ++i) out[i] = arr[i];
        }
    }

    function toMemory32(uint8[10] memory arr) internal pure returns (uint32[] memory out) {
        unchecked {
            out = new uint32[](10);
            for (uint256 i; i < 10; ++i) out[i] = arr[i];
        }
    }

    /* ------------- uint16 ------------- */

    function toMemory32(uint16[1] memory arr) internal pure returns (uint32[] memory out) {
        unchecked {
            out = new uint32[](1);
            for (uint256 i; i < 1; ++i) out[i] = arr[i];
        }
    }

    function toMemory32(uint16[2] memory arr) internal pure returns (uint32[] memory out) {
        unchecked {
            out = new uint32[](2);
            for (uint256 i; i < 2; ++i) out[i] = arr[i];
        }
    }

    function toMemory32(uint16[3] memory arr) internal pure returns (uint32[] memory out) {
        unchecked {
            out = new uint32[](3);
            for (uint256 i; i < 3; ++i) out[i] = arr[i];
        }
    }

    function toMemory32(uint16[4] memory arr) internal pure returns (uint32[] memory out) {
        unchecked {
            out = new uint32[](4);
            for (uint256 i; i < 4; ++i) out[i] = arr[i];
        }
    }

    function toMemory32(uint16[5] memory arr) internal pure returns (uint32[] memory out) {
        unchecked {
            out = new uint32[](5);
            for (uint256 i; i < 5; ++i) out[i] = arr[i];
        }
    }

    function toMemory32(uint16[6] memory arr) internal pure returns (uint32[] memory out) {
        unchecked {
            out = new uint32[](6);
            for (uint256 i; i < 6; ++i) out[i] = arr[i];
        }
    }

    function toMemory32(uint16[7] memory arr) internal pure returns (uint32[] memory out) {
        unchecked {
            out = new uint32[](7);
            for (uint256 i; i < 7; ++i) out[i] = arr[i];
        }
    }

    function toMemory32(uint16[8] memory arr) internal pure returns (uint32[] memory out) {
        unchecked {
            out = new uint32[](8);
            for (uint256 i; i < 8; ++i) out[i] = arr[i];
        }
    }

    function toMemory32(uint16[9] memory arr) internal pure returns (uint32[] memory out) {
        unchecked {
            out = new uint32[](9);
            for (uint256 i; i < 9; ++i) out[i] = arr[i];
        }
    }

    function toMemory32(uint16[10] memory arr) internal pure returns (uint32[] memory out) {
        unchecked {
            out = new uint32[](10);
            for (uint256 i; i < 10; ++i) out[i] = arr[i];
        }
    }

    /* ------------- uint8 ------------- */

    function toMemory(uint8[1] memory arr) internal pure returns (uint256[] memory out) {
        unchecked {
            out = new uint256[](1);
            for (uint256 i; i < 1; ++i) out[i] = arr[i];
        }
    }

    function toMemory(uint8[2] memory arr) internal pure returns (uint256[] memory out) {
        unchecked {
            out = new uint256[](2);
            for (uint256 i; i < 2; ++i) out[i] = arr[i];
        }
    }

    function toMemory(uint8[3] memory arr) internal pure returns (uint256[] memory out) {
        unchecked {
            out = new uint256[](3);
            for (uint256 i; i < 3; ++i) out[i] = arr[i];
        }
    }

    function toMemory(uint8[4] memory arr) internal pure returns (uint256[] memory out) {
        unchecked {
            out = new uint256[](4);
            for (uint256 i; i < 4; ++i) out[i] = arr[i];
        }
    }

    function toMemory(uint8[5] memory arr) internal pure returns (uint256[] memory out) {
        unchecked {
            out = new uint256[](5);
            for (uint256 i; i < 5; ++i) out[i] = arr[i];
        }
    }

    function toMemory(uint8[6] memory arr) internal pure returns (uint256[] memory out) {
        unchecked {
            out = new uint256[](6);
            for (uint256 i; i < 6; ++i) out[i] = arr[i];
        }
    }

    function toMemory(uint8[7] memory arr) internal pure returns (uint256[] memory out) {
        unchecked {
            out = new uint256[](7);
            for (uint256 i; i < 7; ++i) out[i] = arr[i];
        }
    }

    function toMemory(uint8[8] memory arr) internal pure returns (uint256[] memory out) {
        unchecked {
            out = new uint256[](8);
            for (uint256 i; i < 8; ++i) out[i] = arr[i];
        }
    }

    function toMemory(uint8[9] memory arr) internal pure returns (uint256[] memory out) {
        unchecked {
            out = new uint256[](9);
            for (uint256 i; i < 9; ++i) out[i] = arr[i];
        }
    }

    function toMemory(uint8[10] memory arr) internal pure returns (uint256[] memory out) {
        unchecked {
            out = new uint256[](10);
            for (uint256 i; i < 10; ++i) out[i] = arr[i];
        }
    }

    /* ------------- uint16 ------------- */

    function toMemory(uint16[1] memory arr) internal pure returns (uint256[] memory out) {
        unchecked {
            out = new uint256[](1);
            for (uint256 i; i < 1; ++i) out[i] = arr[i];
        }
    }

    function toMemory(uint16[2] memory arr) internal pure returns (uint256[] memory out) {
        unchecked {
            out = new uint256[](2);
            for (uint256 i; i < 2; ++i) out[i] = arr[i];
        }
    }

    function toMemory(uint16[3] memory arr) internal pure returns (uint256[] memory out) {
        unchecked {
            out = new uint256[](3);
            for (uint256 i; i < 3; ++i) out[i] = arr[i];
        }
    }

    function toMemory(uint16[4] memory arr) internal pure returns (uint256[] memory out) {
        unchecked {
            out = new uint256[](4);
            for (uint256 i; i < 4; ++i) out[i] = arr[i];
        }
    }

    function toMemory(uint16[5] memory arr) internal pure returns (uint256[] memory out) {
        unchecked {
            out = new uint256[](5);
            for (uint256 i; i < 5; ++i) out[i] = arr[i];
        }
    }

    function toMemory(uint16[6] memory arr) internal pure returns (uint256[] memory out) {
        unchecked {
            out = new uint256[](6);
            for (uint256 i; i < 6; ++i) out[i] = arr[i];
        }
    }

    function toMemory(uint16[7] memory arr) internal pure returns (uint256[] memory out) {
        unchecked {
            out = new uint256[](7);
            for (uint256 i; i < 7; ++i) out[i] = arr[i];
        }
    }

    function toMemory(uint16[8] memory arr) internal pure returns (uint256[] memory out) {
        unchecked {
            out = new uint256[](8);
            for (uint256 i; i < 8; ++i) out[i] = arr[i];
        }
    }

    function toMemory(uint16[9] memory arr) internal pure returns (uint256[] memory out) {
        unchecked {
            out = new uint256[](9);
            for (uint256 i; i < 9; ++i) out[i] = arr[i];
        }
    }

    function toMemory(uint16[10] memory arr) internal pure returns (uint256[] memory out) {
        unchecked {
            out = new uint256[](10);
            for (uint256 i; i < 10; ++i) out[i] = arr[i];
        }
    }

    /* ------------- uint256 ------------- */

    function toMemory(uint256[1] memory arr) internal pure returns (uint256[] memory out) {
        unchecked {
            out = new uint256[](1);
            for (uint256 i; i < 1; ++i) out[i] = arr[i];
        }
    }

    function toMemory(uint256[2] memory arr) internal pure returns (uint256[] memory out) {
        unchecked {
            out = new uint256[](2);
            for (uint256 i; i < 2; ++i) out[i] = arr[i];
        }
    }

    function toMemory(uint256[3] memory arr) internal pure returns (uint256[] memory out) {
        unchecked {
            out = new uint256[](3);
            for (uint256 i; i < 3; ++i) out[i] = arr[i];
        }
    }

    function toMemory(uint256[4] memory arr) internal pure returns (uint256[] memory out) {
        unchecked {
            out = new uint256[](4);
            for (uint256 i; i < 4; ++i) out[i] = arr[i];
        }
    }

    function toMemory(uint256[5] memory arr) internal pure returns (uint256[] memory out) {
        unchecked {
            out = new uint256[](5);
            for (uint256 i; i < 5; ++i) out[i] = arr[i];
        }
    }

    function toMemory(uint256[6] memory arr) internal pure returns (uint256[] memory out) {
        unchecked {
            out = new uint256[](6);
            for (uint256 i; i < 6; ++i) out[i] = arr[i];
        }
    }

    function toMemory(uint256[7] memory arr) internal pure returns (uint256[] memory out) {
        unchecked {
            out = new uint256[](7);
            for (uint256 i; i < 7; ++i) out[i] = arr[i];
        }
    }

    function toMemory(uint256[8] memory arr) internal pure returns (uint256[] memory out) {
        unchecked {
            out = new uint256[](8);
            for (uint256 i; i < 8; ++i) out[i] = arr[i];
        }
    }

    function toMemory(uint256[9] memory arr) internal pure returns (uint256[] memory out) {
        unchecked {
            out = new uint256[](9);
            for (uint256 i; i < 9; ++i) out[i] = arr[i];
        }
    }

    function toMemory(uint256[10] memory arr) internal pure returns (uint256[] memory out) {
        unchecked {
            out = new uint256[](10);
            for (uint256 i; i < 10; ++i) out[i] = arr[i];
        }
    }
}
