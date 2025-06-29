// SPDX-License-Identifier: WTFPL.ETH
pragma solidity ^0.8.0;

library DAGPB_TestData {
    // Basic string
    string internal constant HelloWorld = "Hello IPFS";

    // Raw CID
    bytes internal constant HelloWorldRaw = hex"0155000a48656c6c6f2049504653";

    // Directory CID
    bytes internal constant DirCID = hex"01700023121d0a0e0155000a48656c6c6f2049504653120968656c6c6f2e747874180a0a020801";

    // Codec values
    bytes internal constant RAW_CODEC = hex"55"; // Tag 85 - Raw
    bytes internal constant DAG_PB_CODEC = hex"70"; // Tag 112 - DAG Protocol Buffers

    // UnixFS types
    uint8 internal constant UnixFS_Type_Raw = 0;
    uint8 internal constant UnixFS_Type_Directory = 1;
    uint8 internal constant UnixFS_Type_File = 2;
    uint8 internal constant UnixFS_Type_Metadata = 3;
    uint8 internal constant UnixFS_Type_Symlink = 4;

    // HEX bytes
    bytes internal constant HelloWorldNode = hex"48656c6c6f2049504653";
    bytes internal constant DirNode = hex"121d0a0e0155000a48656c6c6f2049504653120968656c6c6f2e747874180a0a020801";
}
