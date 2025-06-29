// SPDX-License-Identifier: WTFPL.ETH
pragma solidity ^0.8.25;

import "./json-utf8.sol";
import {LibString} from "solady/utils/LibString.sol";
import {Varint} from "../varint.sol";
import "../utils.sol";

/**
 * @title DAG_JSON
 * @author cidv1.eth
 * @notice DAG-JSON encoding for multiformats
 * @dev This library implements DAG-JSON encoding as defined in the multiformats
 * specification. It provides standardized encoding for JSON data that represents
 * directed acyclic graphs (DAGs) with IPLD links.
 *
 * ⚠️  WARNING: DAG-JSON is string-based and inefficient compared to JSON-UTF8.
 * For most use cases, prefer JSON_UTF8.encode() which provides binary encoding
 * and is more gas-efficient. DAG-JSON should only be used when you specifically
 * need the DAG-JSON format for IPLD compatibility.
 *
 * DAG-JSON encoding supports:
 * - Basic JSON encoding with canonical prefix (0x0129)
 * - IPLD link creation and formatting
 * - Map encoding for key-value pairs
 * - Key-value pair JSON stringification helpers
 *
 * DAG-JSON is used in IPFS and IPLD for representing structured data with
 * content-addressed links. It extends JSON with IPLD link syntax.
 *
 * @custom:security-contact security@cidv1.eth
 * @custom:website https://cidv1.eth
 * @custom:license WTFPL.ETH
 */
library DAG_JSON {
    using Utils for uint256;
    using Varint for uint64;
    // Use the KeyValue struct from JSON_UTF8
    using JSON_UTF8 for JSON_UTF8.KeyValue;

    // DAG-JSON prefix constant: 0x01 (CIDv1) + 0xA9 0x02 (varint for 0x0129)
    bytes3 constant DAG_JSON_PREFIX = 0x01a902;

    /**
     * @notice Encodes data in DAG-JSON format (CIDv1 + varint(0x0129))
     * @param data The data to encode
     * @return result The DAG-JSON encoded data
     * @dev Uses the standard DAG-JSON canonical prefix (0x01a902)
     * @dev Includes varint-encoded length followed by raw data
     * @dev ⚠️  WARNING: Consider using JSON_UTF8.encode() for better efficiency
     */
    function encode(bytes memory data) internal pure returns (bytes memory result) {
        return abi.encodePacked(DAG_JSON_PREFIX, uint64(data.length).varint(), data);
    }

    /**
     * @notice Creates a link in DAG-JSON format
     * @param key The key for the link
     * @param cidv1 The CIDv1 value to link to
     * @return result The DAG-JSON link as bytes
     * @dev Format: {"key":{"/":"f<cidv1-hex>"}}
     * @dev The "f" prefix indicates base16 encoding of the CID
     * @dev ⚠️  WARNING: Consider using JSON_UTF8 for better efficiency
     */
    function link(string memory key, bytes memory cidv1) internal pure returns (bytes memory result) {
        result = abi.encodePacked('{"', key, '":{"/":"f', LibString.toHexStringNoPrefix(cidv1), '"}}');
    }

    /**
     * @notice Encodes an array of key-value pairs into DAG-JSON map format
     * @param kv Array of key-value pairs to encode
     * @return result The DAG-JSON map encoded data
     * @dev Format: {"key1":{"/":"f<value1-hex>"},"key2":{"/":"f<value2-hex>"}}
     * @dev Each value is treated as a CID and formatted as an IPLD link
     * @dev ⚠️  WARNING: Consider using JSON_UTF8 for better efficiency
     */
    function mapDagJson(JSON_UTF8.KeyValue[] memory kv) internal pure returns (bytes memory result) {
        unchecked {
            uint256 length = kv.length;
            result = abi.encodePacked("{");
            bytes memory key;
            bytes memory value;
            for (uint256 i = 0; i < length; i++) {
                if (i > 0) {
                    result = abi.encodePacked(result, ",");
                }
                key = bytes(kv[i].key);
                value = kv[i].value;
                result =
                    abi.encodePacked(result, '"', kv[i].key, '":{"/":"f', LibString.toHexStringNoPrefix(value), '"}');
            }
            result = abi.encodePacked(result, "}");
        }
    }

    /**
     * @notice Converts a KeyValue pair to a DAG-JSON string
     * @param kv The KeyValue pair to convert
     * @return result The DAG-JSON string representation
     * @dev Format: {"key":{"/":"f<hex>"}}
     * @dev The value is formatted as an IPLD link with base16 encoding
     * @dev ⚠️  WARNING: Consider using JSON_UTF8 for better efficiency
     */
    function keyValueToDagJson(JSON_UTF8.KeyValue memory kv) internal pure returns (string memory result) {
        result = string(abi.encodePacked('{"', kv.key, '":{"/":"f', LibString.toHexStringNoPrefix(kv.value), '"}}'));
    }

    /**
     * @notice Converts an array of KeyValue pairs to a DAG-JSON string
     * @param kv Array of KeyValue pairs to convert
     * @return result The DAG-JSON string representation
     * @dev Format: {"key1":{"/":"f<hex1>"},"key2":{"/":"f<hex2>"}}
     * @dev Returns "{}" for empty arrays
     * @dev Each value is formatted as an IPLD link with base16 encoding
     * @dev ⚠️  WARNING: Consider using JSON_UTF8 for better efficiency
     */
    function keyValueArrayToDagJson(JSON_UTF8.KeyValue[] memory kv) internal pure returns (string memory result) {
        if (kv.length == 0) {
            return "{}";
        }

        result = "{";
        for (uint256 i = 0; i < kv.length; i++) {
            if (i > 0) {
                result = string(abi.encodePacked(result, ","));
            }

            result = string(
                abi.encodePacked(result, '"', kv[i].key, '":{"/":"f', LibString.toHexStringNoPrefix(kv[i].value), '"}')
            );
        }
        result = string(abi.encodePacked(result, "}"));
    }
}
