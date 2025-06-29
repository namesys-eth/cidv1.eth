// SPDX-License-Identifier: WTFPL.ETH
pragma solidity ^0.8.25;

import {Varint} from "../varint.sol";

/**
 * @title SHA256
 * @author cidv1.eth
 * @notice SHA-256 multihash encoding for multiformats
 * @dev This library implements SHA-256 multihash encoding as defined in
 * the multihash specification. It provides a standardized way to encode
 * SHA-256 hashes with their multihash prefix.
 *
 * Multihash format:
 * - First byte: hash function code (0x12 for SHA-256)
 * - Second byte: hash length (0x20 = 32 bytes for SHA-256)
 * - Remaining bytes: the actual hash digest
 *
 * @custom:security-contact security@cidv1.eth
 * @custom:website https://cidv1.eth
 * @custom:license WTFPL.ETH
 */
library SHA256 {
    /**
     * @notice Encodes data with SHA-256 multihash
     * @param payload The data to hash and encode
     * @return The SHA-256 multihash encoded data
     * @dev Uses the standard SHA-256 multihash prefix (0x1220)
     * @dev Returns 34 bytes total: 2-byte prefix + 32-byte hash
     */
    function encode(bytes memory payload) internal pure returns (bytes memory) {
        return abi.encodePacked(hex"1220", sha256(payload));
    }

    function _sha256(bytes memory payload) internal pure returns (bytes memory) {
        return abi.encodePacked(hex"1220", sha256(payload));
    }
}
