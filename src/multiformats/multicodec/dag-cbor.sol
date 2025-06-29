// SPDX-License-Identifier: WTFPL.ETH
pragma solidity ^0.8.25;

import {LibBytes} from "solady/utils/LibBytes.sol";
import {Varint} from "../varint.sol";

library DAG_CBOR {
    using LibBytes for bytes;
    using Varint for uint256;

    error InputTooLarge(uint256 input);
    error InvalidDAGCBOR(bytes reason);
    error InvalidFloat(bytes reason);
    error InvalidMapKey(bytes reason);
    error InvalidTag(bytes reason);

    // CBOR major types (from RFC 8949)
    uint8 constant CBOR_TYPE_UINT = 0x00; // Major type 0
    uint8 constant CBOR_TYPE_NEGATIVE_INTEGER = 0x20; // Major type 1
    uint8 constant CBOR_TYPE_BYTE_STRING = 0x40; // Major type 2
    uint8 constant CBOR_TYPE_TEXT_STRING = 0x60; // Major type 3
    uint8 constant CBOR_TYPE_ARRAY = 0x80; // Major type 4
    uint8 constant CBOR_TYPE_MAP = 0xa0; // Major type 5
    uint8 constant CBOR_TYPE_TAG = 0xc0; // Major type 6
    uint8 constant CBOR_TYPE_SIMPLE = 0xe0; // Major type 7

    // DAG-CBOR specific values
    uint8 constant DAG_CBOR_CODEC = 0x71; // DAG-CBOR codec value
    //uint8 constant DAG_CBOR_LINK = 0x2a;   // Tag 42 for CIDs
    bytes constant DAG_CBOR_LINK_TAG = hex"d82a"; // Tag 42 in CBOR format
    bytes constant DAG_CBOR_IDENTITY_PREFIX = hex"00"; // Multibase identity prefix

    // Simple values (major type 7)
    uint8 constant SIMPLE_FALSE = 0xf4; // Simple value 20
    uint8 constant SIMPLE_TRUE = 0xf5; // Simple value 21
    uint8 constant SIMPLE_NULL = 0xf6; // Simple value 22
    uint8 constant SIMPLE_FLOAT_64 = 0xfb; // Simple value 27

    // IEEE 754 special values (not allowed in DAG-CBOR)
    //bytes constant FLOAT_INFINITY = hex"f97c00";
    //bytes constant FLOAT_NAN = hex"f97e00";
    //bytes constant FLOAT_NEG_INFINITY = hex"f9fc00";
    function dagcbor(bytes memory data) internal pure returns (bytes memory) {
        return abi.encodePacked(hex"017100", data.length.varint(), data);
    }

    function dagcborSha256(bytes memory data) internal pure returns (bytes memory) {
        return abi.encodePacked(hex"01711220", sha256(data));
    }

    function dagcborKeccak256(bytes memory data) internal pure returns (bytes memory) {
        return abi.encodePacked(hex"01711b20", keccak256(data));
    }

    /**
     * @notice Encodes length for CBOR values with minimal length
     * @param _len Length to encode
     * @param _type Major type to encode
     * @return result CBOR length encoding
     * @dev Follows DAG-CBOR canonical encoding rules
     * @dev Ensures length is encoded in the shortest possible form
     */
    function encodeLength(uint256 _len, uint8 _type) internal pure returns (bytes memory result) {
        unchecked {
            if (_len < 24) {
                return abi.encodePacked(uint8(_type + _len));
            }
            if (_len < 256) {
                return abi.encodePacked(uint8(_type + 24), uint8(_len));
            }
            if (_len < 65536) {
                return abi.encodePacked(uint8(_type + 25), uint8(_len >> 8), uint8(_len & 0xFF));
            }
            // uint32 max length
            return abi.encodePacked(
                uint8(_type + 26), uint8(_len >> 24), uint8(_len >> 16), uint8(_len >> 8), uint8(_len & 0xFF)
            );
        }
    }

    struct KeyValue {
        string key;
        bytes value;
    }

    /**
     * @notice Encodes a CID tag (42) with binary data
     * @param data Binary data to encode
     * @return result CBOR encoded CID
     * @dev Uses Tag 42 (0xd82a) for CID in DAG-CBOR format
     * @dev Adds Multibase identity prefix (0x00) for raw binary data
     * @dev Follows DAG-CBOR canonical encoding rules
     */
    function encodeCID(bytes memory data) internal pure returns (bytes memory result) {
        return abi.encodePacked(
            DAG_CBOR_LINK_TAG, // Tag 42 in CBOR format
            encodeLength(data.length + 1, CBOR_TYPE_BYTE_STRING), // +1 for the Multibase prefix
            DAG_CBOR_IDENTITY_PREFIX, // Multibase identity prefix
            data
        );
    }

    /**
     * @notice Encodes an array of CIDs into DAG-CBOR array format
     * @param cids Array of CIDs to encode
     * @return result DAG-CBOR array encoded data
     * @dev Each item is encoded as a CID (Tag 42) with Multibase identity prefix
     * @dev Follows DAG-CBOR canonical encoding rules
     */
    function arrayCbor(bytes[] memory cids) internal pure returns (bytes memory result) {
        unchecked {
            uint256 length = cids.length;
            result = encodeLength(length, CBOR_TYPE_ARRAY);
            for (uint256 i = 0; i < length; i++) {
                result = abi.encodePacked(
                    result,
                    DAG_CBOR_LINK_TAG, // Tag 42 for CIDs
                    encodeLength(cids[i].length + 1, CBOR_TYPE_BYTE_STRING),
                    DAG_CBOR_IDENTITY_PREFIX, // +1 for 0x00 prefix
                    cids[i]
                );
            }
        }
    }

    /**
     * @notice Encodes an array of key-value pairs into DAG-CBOR map format
     * @param kv Array of key-value pairs to encode
     * @return result DAG-CBOR map encoded data
     * @dev Keys must be text strings (UTF-8)
     * @dev Values must be CIDs (Tag 42) with Multibase identity prefix
     * @dev Follows DAG-CBOR canonical encoding rules
     */
    function mapCbor(KeyValue[] memory kv) internal pure returns (bytes memory result) {
        unchecked {
            uint256 length = kv.length;
            result = encodeLength(length, CBOR_TYPE_MAP);

            bytes memory key;
            bytes memory value;
            for (uint256 i = 0; i < length; i++) {
                key = bytes(kv[i].key);
                value = kv[i].value;
                result = abi.encodePacked(
                    result,
                    encodeLength(key.length, CBOR_TYPE_TEXT_STRING),
                    key,
                    DAG_CBOR_LINK_TAG, // Tag 42 for CIDs
                    encodeLength(value.length + 1, CBOR_TYPE_BYTE_STRING),
                    DAG_CBOR_IDENTITY_PREFIX, // +1 for 0x00 prefix
                    value
                );
            }
        }
    }

    /**
     * @notice Encodes a complete DAG-CBOR node with data and links
     * @param data Optional data field (empty bytes if none)
     * @param links Array of links (CIDs)
     * @return result Complete DAG-CBOR node
     * @dev If data is empty, creates a directory node
     * @dev If links is empty, creates a file node
     * @dev If both are present, creates a complete node
     * @dev Follows DAG-CBOR canonical encoding rules
     */
    function nodeCbor(bytes memory data, bytes[] memory links) internal pure returns (bytes memory result) {
        if (data.length == 0 && links.length == 0) {
            revert InvalidDAGCBOR("Empty node");
        }
        if (data.length == 0) {
            // Directory node - array of links
            return arrayCbor(links);
        }
        if (links.length == 0) {
            // File node - just the data
            return data;
        }
        // Complete node - map with data and links
        KeyValue[] memory kv = new KeyValue[](2);
        kv[0] = KeyValue("Data", data);
        kv[1] = KeyValue("Links", arrayCbor(links));
        return mapCbor(kv);
    }
}
