// SPDX-License-Identifier: WTFPL.ETH
pragma solidity ^0.8.25;

import {Varint} from "../varint.sol";

/**
 * @title Raw
 * @author cidv1.eth
 * @notice Raw binary encoding for multiformats
 * @dev This library implements raw binary encoding as defined in the multiformats
 * specification. It provides standardized encoding for raw binary data with
 * various hash function options.
 * 
 * Raw binary encoding supports:
 * - Raw encoding (no hashing)
 * - SHA-256 hashing
 * - Keccak-256 hashing
 * 
 * The library follows the multiformats specification for raw binary codec
 * values and provides a clean, minimal API for encoding operations.
 * 
 * @custom:security-contact security@cidv1.eth
 * @custom:website https://cidv1.eth
 * @custom:license WTFPL.ETH
 */
library Raw {
    using Varint for uint256;

    /**
     * @notice Encodes data as raw binary
     * @param data The data to encode
     * @return result The raw binary encoded data
     * @dev Uses the standard raw binary prefix (0x015500)
     * @dev Includes varint-encoded length followed by raw data
     */
    function encode(bytes memory data) internal pure returns (bytes memory result) {
        result = abi.encodePacked(hex"015500", data.length.varint(), data);
    }

    /**
     * @notice Encodes data as raw binary with SHA256 hash
     * @param data The data to hash and encode
     * @return result The raw binary encoded data with SHA256 hash
     * @dev Uses the standard raw binary SHA256 prefix (0x01551220)
     * @dev Returns 36 bytes total: 4-byte prefix + 32-byte hash
     */
    function encodeSha256(bytes memory data) internal pure returns (bytes memory result) {
        result = abi.encodePacked(hex"01551220", sha256(data));
    }

    /**
     * @notice Encodes data as raw binary with Keccak256 hash
     * @param data The data to hash and encode
     * @return result The raw binary encoded data with Keccak256 hash
     * @dev Uses the standard raw binary Keccak256 prefix (0x01551b20)
     * @dev Returns 36 bytes total: 4-byte prefix + 32-byte hash
     */
    function encodeKeccak256(bytes memory data) internal pure returns (bytes memory result) {
        result = abi.encodePacked(hex"01551b20", keccak256(data));
    }
}
