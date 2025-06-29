// SPDX-License-Identifier: WTFPL.ETH
pragma solidity ^0.8.25;

import {Varint} from "../varint.sol";

/// @title DAG-PB
/// @notice A codec that implements a very small subset of the IPLD Data Model in Protocol Buffers format
/// @dev DAG-PB is a strict subset of Protocol Buffers with specific schema and constraints
library DAG_PB {
    using Varint for uint256;

    // Codec values
    bytes constant DAG_PB_CODEC = hex"70"; // Tag 112 - DAG Protocol Buffers
    bytes constant PB_DIR_TYPE = hex"0a020801";
    // Wire types for Protocol Buffers
    uint8 constant WIRE_TYPE_VARINT = 0;
    uint8 constant WIRE_TYPE_LENGTH_DELIMITED = 2;

    // Field numbers for UnixFS Data message
    uint8 constant FIELD_TYPE = 1;
    uint8 constant FIELD_DATA = 2;
    uint8 constant FIELD_FILESIZE = 3;
    uint8 constant FIELD_BLOCKSIZES = 4;

    // Field numbers for PBLink message
    uint8 constant FIELD_HASH = 1;
    uint8 constant FIELD_NAME = 2;
    uint8 constant FIELD_TSIZE = 3;

    // Field numbers for PBNode message
    uint8 constant FIELD_LINKS = 2;

    // UnixFS types
    uint8 constant UnixFS_Type_Raw = 0;
    uint8 constant UnixFS_Type_Directory = 1;
    uint8 constant UnixFS_Type_File = 2;
    uint8 constant UnixFS_Type_Metadata = 3;
    uint8 constant UnixFS_Type_Symlink = 4;

    /**
     * @notice Encodes a tag and wire type for a Protocol Buffer field
     * @param fieldNum Field number
     * @param wireType Wire type
     * @return bytes Encoded tag
     */
    function encodeTag(uint8 fieldNum, uint8 wireType) internal pure returns (bytes memory) {
        return ((uint256(fieldNum) << 3) | wireType).varint();
    }

    /**
     * @notice Encodes a string field in Protocol Buffer format
     * @param fieldNum Field number
     * @param value String value
     * @return bytes Encoded field
     */
    function encodeString(uint8 fieldNum, string memory value) internal pure returns (bytes memory) {
        return abi.encodePacked(
            ((uint256(fieldNum) << 3) | WIRE_TYPE_LENGTH_DELIMITED).varint(),
            //encodeTag(fieldNum, WIRE_TYPE_LENGTH_DELIMITED),
            bytes(value).length.varint(),
            value
        );
    }

    /**
     * @notice Encodes a bytes field in Protocol Buffer format
     * @param fieldNum Field number
     * @param value Bytes value
     * @return bytes Encoded field
     */
    function encodeBytes(uint8 fieldNum, bytes memory value) internal pure returns (bytes memory) {
        return abi.encodePacked(
            ((uint256(fieldNum) << 3) | WIRE_TYPE_LENGTH_DELIMITED).varint(), bytes(value).length.varint(), value
        );
    }

    /**
     * @notice Encodes a uint64 field in Protocol Buffer format
     * @param fieldNum Field number
     * @param value Uint64 value
     * @return bytes Encoded field
     */
    function encodeUint64(uint8 fieldNum, uint256 value) internal pure returns (bytes memory) {
        return abi.encodePacked(encodeTag(fieldNum, WIRE_TYPE_VARINT), value.varint());
    }

    /**
     * @notice Encodes a PBLink message
     * @param hash CID hash
     * @param name Link name
     * @param tsize Target size (optional)
     * @return result Encoded PBLink message
     */
    function encodePBLink(bytes memory hash, string memory name, uint256 tsize)
        internal
        pure
        returns (bytes memory result)
    {
        bytes memory hashField = encodeBytes(FIELD_HASH, hash);
        bytes memory nameField = encodeString(FIELD_NAME, name);
        bytes memory tsizeField;
        if (tsize > 0) {
            tsizeField = encodeUint64(FIELD_TSIZE, tsize);
        }
        // match JS/IPFS order
        return abi.encodePacked(hashField, nameField, tsizeField);
    }

    /**
     * @notice Encodes a PBNode message
     * @param data Data field
     * @param links Array of PBLink messages
     * @return result Encoded PBNode message
     */
    function encodePBNode(bytes memory data, bytes[] memory links) internal pure returns (bytes memory) {
        bytes memory out;
        for (uint256 i = 0; i < links.length; i++) {
            out = abi.encodePacked(out, encodeBytes(FIELD_LINKS, links[i]));
        }
        return abi.encodePacked(out, data);
    }

    /**
     * @notice Creates a raw file node
     * @param data File data
     * @return result Raw file node
     */
    function rawFile(bytes memory data) internal pure returns (bytes memory) {
        return data;
    }

    /**
     * @notice Creates a DAG-PB directory node
     * @param links Array of PBLink messages
     * @return result DAG-PB directory node
     */
    function directory(bytes[] memory links) internal pure returns (bytes memory result) {
        return encodePBNode(PB_DIR_TYPE, links);
    }

    /**
     * @notice Creates a DAG-PB link
     * @param hash CID hash
     * @param name Link name
     * @param tsize Target size (optional, defaults to 0)
     * @return result DAG-PB link
     */
    function link(bytes memory hash, string memory name, uint256 tsize) internal pure returns (bytes memory result) {
        return encodePBLink(hash, name, tsize);
    }

    /**
     * @notice Creates a DAG-PB link (overload with default tsize=0)
     * @param hash CID hash
     * @param name Link name
     * @return result DAG-PB link
     */
    function link(bytes memory hash, string memory name) internal pure returns (bytes memory result) {
        return encodePBLink(hash, name, 0);
    }
}
