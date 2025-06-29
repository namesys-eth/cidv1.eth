// SPDX-License-Identifier: WTFPL.ETH
pragma solidity ^0.8.25;

import {Varint} from "../varint.sol";

/**
 * @title KECCAK256
 * @author cidv1.eth
 * @notice Keccak-256 multihash encoding for multiformats
 * @dev This library implements Keccak-256 multihash encoding as defined in
 * the multihash specification. It provides a standardized way to encode
 * Keccak-256 hashes with their multihash prefix.
 * 
 * Multihash format:
 * - First byte: hash function code (0x1b for Keccak-256)
 * - Second byte: hash length (0x20 = 32 bytes for Keccak-256)
 * - Remaining bytes: the actual hash digest
 * 
 * Note: Keccak-256 is the hash function used by Ethereum and is different
 * from SHA-3, despite being based on the same algorithm.
 * 
 * @custom:security-contact security@cidv1.eth
 * @custom:website https://cidv1.eth
 * @custom:license WTFPL.ETH
 */
library KECCAK256 {
    /**
     * @notice Encodes data with Keccak-256 multihash
     * @param data The data to hash and encode
     * @return The Keccak-256 multihash encoded data
     * @dev Uses the standard Keccak-256 multihash prefix (0x1b20)
     * @dev Returns 34 bytes total: 2-byte prefix + 32-byte hash
     */
    function encode(bytes memory data) internal pure returns (bytes memory) {
        return abi.encodePacked(hex"1b20", keccak256(data));
    }

    function _keccak256(bytes memory data) internal pure returns (bytes memory) {
        return abi.encodePacked(hex"1b20", keccak256(data));
    }
}
