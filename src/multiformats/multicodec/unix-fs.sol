// SPDX-License-Identifier: WTFPL.ETH
pragma solidity ^0.8.25;

import {DAG_PB} from "./dag-pb.sol";

/// @title UnixFS
/// @notice Implementation of UnixFS data structures for IPFS
/// @dev UnixFS is a protocol and format for representing files and directories in IPFS
/// @dev See https://github.com/ipfs/specs/blob/main/UNIXFS.md for more details
library UnixFS {
    using DAG_PB for bytes;

    // UnixFS types
    uint8 constant RAW = 0;
    uint8 constant DIRECTORY = 1;
    uint8 constant FILE = 2;
    uint8 constant METADATA = 3;
    uint8 constant SYMLINK = 4;

    // UnixFS field numbers
    uint8 constant Data_Type = 1;
    uint8 constant Data_Data = 2;
    uint8 constant Data_Filesize = 3;
    uint8 constant Data_Blocksizes = 4;

    /**
     * @notice Creates a raw UnixFS node
     * @param data Raw data
     * @return result DAG-PB node with UnixFS data
     */
    function raw(bytes memory data) internal pure returns (bytes memory result) {
        bytes memory unixfsData = encodeUnixFSData(RAW, data, 0, new uint64[](0));
        return DAG_PB.rawFile(unixfsData);
    }

    /**
     * @notice Creates a file UnixFS node
     * @param data File data
     * @param filesize Total file size
     * @param blocksizes Array of block sizes
     * @return result DAG-PB node with UnixFS data
     */
    function file(bytes memory data, uint64 filesize, uint64[] memory blocksizes)
        internal
        pure
        returns (bytes memory result)
    {
        bytes memory unixfsData = encodeUnixFSData(FILE, data, filesize, blocksizes);
        return DAG_PB.rawFile(unixfsData);
    }

    /**
     * @notice Creates a directory UnixFS node
     * @param hashes Array of link hashes
     * @param names Array of link names
     * @return result DAG-PB node with UnixFS data
     * @dev If arrays have different lengths, uses the minimum length (GiGo principle)
     */
    function directory(bytes[] memory hashes, string[] memory names) internal pure returns (bytes memory result) {
        bytes memory unixfsData = encodeUnixFSData(DIRECTORY, "", 0, new uint64[](0));
        
        // Use minimum length to handle mismatched arrays gracefully (GiGo)
        uint256 minLength = hashes.length < names.length ? hashes.length : names.length;
        bytes[] memory links = new bytes[](minLength);
        
        for (uint256 i = 0; i < minLength; i++) {
            links[i] = DAG_PB.encodePBLink(hashes[i], names[i], 0);
        }
        
        return DAG_PB.encodePBNode(unixfsData, links);
    }

    /**
     * @notice Creates a symlink UnixFS node
     * @param target Target path
     * @return result DAG-PB node with UnixFS data
     */
    function symlink(string memory target) internal pure returns (bytes memory result) {
        bytes memory unixfsData = encodeUnixFSData(SYMLINK, bytes(target), 0, new uint64[](0));
        return DAG_PB.rawFile(unixfsData);
    }

    /**
     * @notice Creates a metadata UnixFS node
     * @param data Metadata data
     * @return result DAG-PB node with UnixFS data
     */
    function metadata(bytes memory data) internal pure returns (bytes memory result) {
        bytes memory unixfsData = encodeUnixFSData(METADATA, data, 0, new uint64[](0));
        return DAG_PB.rawFile(unixfsData);
    }

    /**
     * @notice Encodes UnixFS data structure
     * @param type_ UnixFS type
     * @param data Data field
     * @param filesize Total file size
     * @param blocksizes Array of block sizes
     * @return result Encoded UnixFS data
     */
    function encodeUnixFSData(uint8 type_, bytes memory data, uint64 filesize, uint64[] memory blocksizes)
        internal
        pure
        returns (bytes memory result)
    {
        // For directory nodes, encode type directly as a single byte
        if (type_ == DIRECTORY) {
            return abi.encodePacked(bytes1(type_));
        }

        // For other types, encode as Protocol Buffer message
        // Field 1: type (uint64) - always encode type
        bytes memory typeField = DAG_PB.encodeUint64(Data_Type, uint64(type_));

        // Field 2: data (bytes) - only encode if non-empty
        bytes memory dataField = "";
        if (data.length > 0) {
            dataField = DAG_PB.encodeBytes(Data_Data, data);
        }

        // Field 3: filesize (uint64) - only encode if non-zero
        bytes memory filesizeField = "";
        if (filesize > 0) {
            filesizeField = DAG_PB.encodeUint64(Data_Filesize, filesize);
        }

        // Field 4: blocksizes (repeated uint64) - only encode if non-zero
        bytes memory blocksizesField = "";
        for (uint256 i = 0; i < blocksizes.length; i++) {
            if (blocksizes[i] > 0) {
                blocksizesField = abi.encodePacked(blocksizesField, DAG_PB.encodeUint64(Data_Blocksizes, blocksizes[i]));
            }
        }

        // Combine fields
        result = abi.encodePacked(typeField, dataField, filesizeField, blocksizesField);
    }
}
