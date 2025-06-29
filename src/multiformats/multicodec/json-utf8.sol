// SPDX-License-Identifier: WTFPL.ETH
pragma solidity ^0.8.25;

import {Varint} from "../varint.sol";
import {LibString} from "solady/utils/LibString.sol";

/**
 * @title JSON_UTF8
 * @author cidv1.eth
 * @notice JSON UTF-8 encoding for multiformats
 * @dev This library implements JSON UTF-8 encoding as defined in the multiformats
 * specification. It provides standardized encoding for JSON data with UTF-8
 * encoding and various hash function options.
 * 
 * JSON UTF-8 encoding supports:
 * - Raw encoding (no hashing)
 * - SHA-256 hashing
 * - Keccak-256 hashing
 * - Key-value pair JSON stringification helpers
 * 
 * The library follows the multiformats specification for JSON UTF-8 codec
 * values and provides a clean, minimal API for encoding operations.
 * 
 * @custom:security-contact security@cidv1.eth
 * @custom:website https://cidv1.eth
 * @custom:license WTFPL.ETH
 */
library JSON_UTF8 {
    using Varint for uint256;

    /**
     * @notice Key-value pair structure for JSON operations
     * @param key The JSON key (string)
     * @param value The JSON value (bytes)
     */
    struct KeyValue {
        string key;
        bytes value;
    }

    // Codec constants for JSON UTF-8
    bytes constant JSON_UTF8_RAW = hex"01800400";
    bytes constant JSON_UTF8_SHA256 = hex"0180041220";
    bytes constant JSON_UTF8_KECCAK256 = hex"0180041b20";

    /**
     * @notice Encodes data as JSON UTF-8 (raw)
     * @param data The data to encode
     * @return The JSON UTF-8 encoded data with raw prefix
     * @dev Uses the standard JSON UTF-8 raw prefix (0x01800400)
     * @dev Includes varint-encoded length followed by raw data
     */
    function encode(bytes memory data) internal pure returns (bytes memory) {
        return abi.encodePacked(JSON_UTF8_RAW, data.length.varint(), data);
    }

    /**
     * @notice Encodes data as JSON UTF-8 with SHA256 hash
     * @param data The data to hash and encode
     * @return The JSON UTF-8 encoded data with SHA256 hash
     * @dev Uses the standard JSON UTF-8 SHA256 prefix (0x0180041220)
     * @dev Returns 36 bytes total: 4-byte prefix + 32-byte hash
     */
    function encodeSha256(bytes memory data) internal pure returns (bytes memory) {
        return abi.encodePacked(JSON_UTF8_SHA256, sha256(data));
    }

    /**
     * @notice Encodes data as JSON UTF-8 with Keccak256 hash
     * @param data The data to hash and encode
     * @return The JSON UTF-8 encoded data with Keccak256 hash
     * @dev Uses the standard JSON UTF-8 Keccak256 prefix (0x0180041b20)
     * @dev Returns 36 bytes total: 4-byte prefix + 32-byte hash
     */
    function encodeKeccak256(bytes memory data) internal pure returns (bytes memory) {
        return abi.encodePacked(JSON_UTF8_KECCAK256, keccak256(data));
    }

    // --- KeyValue helpers ---

    /**
     * @notice Converts a KeyValue pair to a JSON string with hex value
     * @param kv The KeyValue pair to convert
     * @return The JSON string representation with 0x-prefixed hex value
     * @dev Format: {"key":"0x<hex-value>"}
     */
    function kvJsonHex(KeyValue memory kv) internal pure returns (string memory) {
       return string(abi.encodePacked('{"', kv.key, '":"0x', LibString.toHexStringNoPrefix(kv.value), '"}'));
    }

    /**
     * @notice Converts a KeyValue pair to a JSON string with custom prefix
     * @param kv The KeyValue pair to convert
     * @param prefix The prefix to add before the hex value (e.g., "f" for base16)
     * @return The JSON string representation with custom prefix
     * @dev Format: {"key":"<prefix><hex-value>"}
     */
    function kvJsonHexPrefixed(KeyValue memory kv, bytes memory prefix) internal pure returns (string memory) {
       return string(
            abi.encodePacked(
                '{"',
                kv.key,
                '":"',
                prefix,
                LibString.toHexStringNoPrefix(kv.value),
                '"}'
            )
        );
    }

    /**
     * @notice Converts a KeyValue pair to a JSON string with string value
     * @param kv The KeyValue pair to convert
     * @return The JSON string representation with string value
     * @dev Format: {"key":"value"}
     * @dev Assumes the value bytes represent a valid UTF-8 string
     */
    function kvJsonString(KeyValue memory kv) internal pure returns (string memory) {
       return string(abi.encodePacked('{"', kv.key, '":"', string(kv.value), '"}'));
    }
}
