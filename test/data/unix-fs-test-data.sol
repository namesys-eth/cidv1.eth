// SPDX-License-Identifier: WTFPL.ETH
pragma solidity ^0.8.0;

library UnixFS_TestData {
    // Basic test data
    string internal constant HelloWorld = "Hello IPFS";
    string internal constant SimpleFile = "This is a simple file content";
    string internal constant SymlinkTarget = "../data/hello.txt";

    // Expected encoded UnixFS data for different types

    // Raw type: just the type byte (0x00)
    bytes internal constant RawType = hex"00";

    // Directory type: just the type byte (0x01)
    bytes internal constant DirectoryType = hex"01";

    // File type with data: protobuf encoded [type=2, data="Hello IPFS"]
    // Field 1 (type): 0x08 0x02
    // Field 2 (data): 0x12 0x0a "Hello IPFS"
    bytes internal constant FileWithData = hex"0802120a48656c6c6f2049504653";

    // File type with filesize: protobuf encoded [type=2, filesize=10]
    // Field 1 (type): 0x08 0x02
    // Field 3 (filesize): 0x18 0x0a
    bytes internal constant FileWithSize = hex"0802180a";

    // File type with blocksizes: protobuf encoded [type=2, blocksizes=[1024, 2048]]
    // Field 1 (type): 0x08 0x02
    // Field 4 (blocksizes): 0x20 0x80 0x08, 0x20 0x80 0x10 (varint encoded)
    bytes internal constant FileWithBlocksizes = hex"0802208008208010";

    // Symlink type with target: protobuf encoded [type=4, data="../data/hello.txt"]
    // Field 1 (type): 0x08 0x04
    // Field 2 (data): 0x12 0x10 "../data/hello.txt"
    bytes internal constant SymlinkWithTarget = hex"080412102e2e2f646174612f68656c6c6f2e747874";

    // Metadata type with data: protobuf encoded [type=3, data="metadata content"]
    // Field 1 (type): 0x08 0x03
    // Field 2 (data): 0x12 0x10 "metadata content"
    bytes internal constant MetadataWithData = hex"080312106d657461646174612063636f6e74656e74";

    // Test file names and hashes for directory tests
    string internal constant FileName1 = "hello.txt";
    string internal constant FileName2 = "world.txt";

    // Mock hashes for testing (32 bytes each)
    bytes internal constant Hash1 = hex"1220ba7816bf8f01cfea414140de5dae2223b00361a396177a9cb410ff61f20015ad";
    bytes internal constant Hash2 = hex"1220b94d27b9934d3e08a52e52d7da7dabfac484efe37a5380ee9088f7ace2efcde9";

    // Expected DAG-PB encoded directory with UnixFS data
    // This would be created by the directory() function
    bytes internal constant ExpectedDirectory = hex"0a020801";

    // Complex file with all fields: type=2, data="content", filesize=7, blocksizes=[7]
    bytes internal constant ComplexFile = hex"08021207636f6e74656e7418072007";
}
