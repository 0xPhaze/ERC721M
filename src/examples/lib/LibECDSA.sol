// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

library LibECDSA {
    function toEthSignedMsgHash(bytes32 hash) internal pure returns (bytes32) {
        return keccak256(abi.encodePacked("\x19Ethereum Signed Message:\n32", hash));
    }

    function isValidSignature(
        bytes32 hash,
        bytes calldata signature,
        address signer
    ) internal pure returns (bool) {
        address recovered = ecrecover(
            hash,
            uint8(bytes1(signature[64:65])),
            bytes32(signature[0:32]),
            bytes32(signature[32:64])
        );
        return recovered != address(0) && recovered == signer;
    }
}
