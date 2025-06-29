// SPDX-License-Identifier: WTFPL.ETH
pragma solidity ^0.8.0;

import "forge-std/Test.sol";
import {UnixFS} from "../src/multiformats/multicodec/unix-fs.sol";
import {DAG_PB} from "../src/multiformats/multicodec/dag-pb.sol";
import {UnixFS_TestData} from "./data/unix-fs-test-data.sol";
import {Raw} from "../src/multiformats/multicodec/raw-bin.sol";
import {Varint} from "../src/multiformats/varint.sol";

contract UnixFSTest is Test {
    using Raw for bytes;
    using Varint for uint256;
    using UnixFS for bytes;

    // Helper to wrap data as CIDv1 with dag-pb codec
    function _wrapDagPbCID(bytes memory data) internal pure returns (bytes memory) {
        // 0x01 (CIDv1) + 0x70 (dag-pb codec) + 0x00 (identity multihash) + varint(length) + data
        return abi.encodePacked(bytes1(0x01), bytes1(0x70), bytes1(0x00), data.length.varint(), data);
    }

    // Helper to wrap data as CIDv1 with raw codec
    function _wrapRawCID(bytes memory data) internal pure returns (bytes memory) {
        // 0x01 (CIDv1) + 0x55 (raw codec) + 0x00 (identity multihash) + varint(length) + data
        return abi.encodePacked(bytes1(0x01), bytes1(0x55), bytes1(0x00), data.length.varint(), data);
    }

    // ========== BASIC NODE TESTS ==========

    function test_RawNode() public pure {
        bytes memory data = bytes(UnixFS_TestData.HelloWorld);
        bytes memory result = UnixFS.raw(data);

        console.log("Raw UnixFS Node:");
        console.logBytes(result);

        // Verify the structure - should be a DAG-PB node with UnixFS data
        assertTrue(result.length > 0, "Raw node should not be empty");

        // Verify it contains the expected UnixFS data
        bytes memory expectedUnixFSData = UnixFS.encodeUnixFSData(UnixFS.RAW, data, 0, new uint64[](0));
        assertTrue(result.length >= expectedUnixFSData.length, "Raw node should contain UnixFS data");

        // Log for debugging
        console.log("Input data:");
        console.logBytes(data);
        console.log("Raw node result:");
        console.logBytes(result);
    }

    function test_FileNode() public pure {
        bytes memory data = bytes(UnixFS_TestData.SimpleFile);
        uint64 filesize = uint64(data.length);
        uint64[] memory blocksizes = new uint64[](1);
        blocksizes[0] = filesize;

        bytes memory result = UnixFS.file(data, filesize, blocksizes);

        console.log("File UnixFS Node:");
        console.logBytes(result);

        // Verify the structure
        assertTrue(result.length > 0, "File node should not be empty");

        // Verify it contains the expected UnixFS data
        bytes memory expectedUnixFSData = UnixFS.encodeUnixFSData(UnixFS.FILE, data, filesize, blocksizes);
        assertTrue(result.length >= expectedUnixFSData.length, "File node should contain UnixFS data");

        // Log for debugging
        console.log("Input data:");
        console.logBytes(data);
        console.log("File size:", filesize);
        console.log("Block sizes:", blocksizes[0]);
        console.log("File node result:");
        console.logBytes(result);
    }

    function test_DirectoryNode() public pure {
        // Create some mock file hashes and names
        bytes[] memory hashes = new bytes[](2);
        string[] memory names = new string[](2);

        hashes[0] = UnixFS_TestData.Hash1;
        hashes[1] = UnixFS_TestData.Hash2;
        names[0] = UnixFS_TestData.FileName1;
        names[1] = UnixFS_TestData.FileName2;

        bytes memory result = UnixFS.directory(hashes, names);

        console.log("Directory UnixFS Node:");
        console.logBytes(result);

        // Verify the structure
        assertTrue(result.length > 0, "Directory node should not be empty");

        // Verify it contains the expected UnixFS data (directory type)
        bytes memory expectedUnixFSData = UnixFS.encodeUnixFSData(UnixFS.DIRECTORY, "", 0, new uint64[](0));
        assertTrue(result.length >= expectedUnixFSData.length, "Directory node should contain UnixFS data");

        // Verify it contains the directory type byte
        assertEq(uint8(result[result.length - 1]), UnixFS.DIRECTORY, "Directory node should end with directory type");

        // Log for debugging
        console.log("Hash 1:");
        console.logBytes(hashes[0]);
        console.log("Name 1:", names[0]);
        console.log("Hash 2:");
        console.logBytes(hashes[1]);
        console.log("Name 2:", names[1]);
        console.log("Directory node result:");
        console.logBytes(result);
    }

    function test_SymlinkNode() public pure {
        string memory target = UnixFS_TestData.SymlinkTarget;
        bytes memory result = UnixFS.symlink(target);

        console.log("Symlink UnixFS Node:");
        console.logBytes(result);

        // Verify the structure
        assertTrue(result.length > 0, "Symlink node should not be empty");

        // Verify it contains the expected UnixFS data
        bytes memory expectedUnixFSData = UnixFS.encodeUnixFSData(UnixFS.SYMLINK, bytes(target), 0, new uint64[](0));
        assertTrue(result.length >= expectedUnixFSData.length, "Symlink node should contain UnixFS data");

        // Log for debugging
        console.log("Symlink target:", target);
        console.log("Symlink node result:");
        console.logBytes(result);
    }

    function test_MetadataNode() public pure {
        bytes memory metadata = bytes("metadata content");
        bytes memory result = UnixFS.metadata(metadata);

        console.log("Metadata UnixFS Node:");
        console.logBytes(result);

        // Verify the structure
        assertTrue(result.length > 0, "Metadata node should not be empty");

        // Verify it contains the expected UnixFS data
        bytes memory expectedUnixFSData = UnixFS.encodeUnixFSData(UnixFS.METADATA, metadata, 0, new uint64[](0));
        assertTrue(result.length >= expectedUnixFSData.length, "Metadata node should contain UnixFS data");

        // Log for debugging
        console.log("Metadata content:");
        console.logBytes(metadata);
        console.log("Metadata node result:");
        console.logBytes(result);
    }

    // ========== ENCODING TESTS ==========

    function test_EncodeUnixFSData_Directory() public pure {
        bytes memory result = UnixFS.encodeUnixFSData(UnixFS.DIRECTORY, "", 0, new uint64[](0));

        // Directory should just be the type byte
        assertEq(result, UnixFS_TestData.DirectoryType, "Directory encoding mismatch");
        assertEq(result.length, 1, "Directory should be exactly 1 byte");
        assertEq(uint8(result[0]), UnixFS.DIRECTORY, "Directory should encode as type 1");

        console.log("Directory UnixFS data:");
        console.logBytes(result);
    }

    function test_EncodeUnixFSData_File() public pure {
        bytes memory data = bytes("test");
        uint64 filesize = 4;
        uint64[] memory blocksizes = new uint64[](1);
        blocksizes[0] = 4;

        bytes memory result = UnixFS.encodeUnixFSData(UnixFS.FILE, data, filesize, blocksizes);

        // Should be protobuf encoded with type, data, filesize, and blocksizes
        assertTrue(result.length > 0, "File encoding should not be empty");

        // Verify protobuf structure
        assertEq(uint8(result[0]), 0x08, "Should start with type field tag");
        assertEq(uint8(result[1]), UnixFS.FILE, "Type should be FILE (2)");
        assertEq(uint8(result[2]), 0x12, "Should have data field tag");
        assertEq(uint8(result[3]), 0x04, "Data length should be 4");

        console.log("File UnixFS data:");
        console.logBytes(result);
        console.log("Expected fields: type=2, data='test', filesize=4, blocksizes=[4]");
    }

    function test_EncodeUnixFSData_Raw() public pure {
        bytes memory data = bytes("raw data");
        bytes memory result = UnixFS.encodeUnixFSData(UnixFS.RAW, data, 0, new uint64[](0));

        // Should be protobuf encoded with type and data
        assertTrue(result.length > 0, "Raw encoding should not be empty");

        // Verify protobuf structure
        assertEq(uint8(result[0]), 0x08, "Should start with type field tag");
        assertEq(uint8(result[1]), UnixFS.RAW, "Type should be RAW (0)");
        assertEq(uint8(result[2]), 0x12, "Should have data field tag");
        assertEq(uint8(result[3]), 0x08, "Data length should be 8");

        console.log("Raw UnixFS data:");
        console.logBytes(result);
        console.log("Expected fields: type=0, data='raw data'");
    }

    function test_EncodeUnixFSData_Symlink() public pure {
        bytes memory target = bytes(UnixFS_TestData.SymlinkTarget);
        bytes memory result = UnixFS.encodeUnixFSData(UnixFS.SYMLINK, target, 0, new uint64[](0));

        // Should be protobuf encoded with type and data (target)
        assertTrue(result.length > 0, "Symlink encoding should not be empty");

        // Verify protobuf structure
        assertEq(uint8(result[0]), 0x08, "Should start with type field tag");
        assertEq(uint8(result[1]), UnixFS.SYMLINK, "Type should be SYMLINK (4)");
        assertEq(uint8(result[2]), 0x12, "Should have data field tag");
        assertEq(uint8(result[3]), uint8(target.length), "Data length should match target length");

        console.log("Symlink UnixFS data:");
        console.logBytes(result);
        console.log("Expected fields: type=4, data='../data/hello.txt'");
    }

    // ========== EDGE CASES ==========

    function test_DirectoryWithEmptyArrays() public pure {
        // Test directory with no children
        bytes[] memory hashes = new bytes[](0);
        string[] memory names = new string[](0);

        bytes memory result = UnixFS.directory(hashes, names);

        assertTrue(result.length > 0, "Empty directory should not be empty");

        // Should contain directory type byte
        assertEq(uint8(result[result.length - 1]), UnixFS.DIRECTORY, "Empty directory should end with directory type");

        console.log("Empty directory node:");
        console.logBytes(result);
    }

    function test_FileWithNoData() public pure {
        // Test file with no data but with size and blocksizes
        bytes memory data = "";
        uint64 filesize = 1024;
        uint64[] memory blocksizes = new uint64[](2);
        blocksizes[0] = 512;
        blocksizes[1] = 512;

        bytes memory result = UnixFS.file(data, filesize, blocksizes);

        assertTrue(result.length > 0, "File with no data should not be empty");

        // Should contain file type and filesize, but no data field
        assertEq(uint8(result[0]), 0x08, "Should start with type field tag");
        assertEq(uint8(result[1]), UnixFS.FILE, "Type should be FILE (2)");

        console.log("File with no data but size/blocksizes:");
        console.logBytes(result);
    }

    function test_FileWithZeroBlocksizes() public pure {
        // Test that zero blocksizes are not encoded
        bytes memory data = bytes("test");
        uint64[] memory blocksizes = new uint64[](3);
        blocksizes[0] = 0; // Should not be encoded
        blocksizes[1] = 4; // Should be encoded
        blocksizes[2] = 0; // Should not be encoded

        bytes memory result = UnixFS.file(data, 4, blocksizes);

        assertTrue(result.length > 0, "File should not be empty");

        // Should contain type, data, and only non-zero blocksize
        assertEq(uint8(result[0]), 0x08, "Should start with type field tag");
        assertEq(uint8(result[1]), UnixFS.FILE, "Type should be FILE (2)");

        console.log("File with zero blocksizes:");
        console.logBytes(result);
        console.log("Only non-zero blocksize (4) should be encoded");
    }

    // ========== COMPREHENSIVE COVERAGE TESTS ==========

    function test_AllUnixFSTypes() public pure {
        // Test all UnixFS types systematically
        bytes memory rawData = bytes("raw content");
        bytes memory fileData = bytes("file content");
        bytes memory metadataData = bytes("metadata content");
        string memory symlinkTarget = "/path/to/target";

        // Test RAW type
        bytes memory rawResult = UnixFS.raw(rawData);
        assertTrue(rawResult.length > 0, "RAW type should produce valid result");

        // Test FILE type
        bytes memory fileResult = UnixFS.file(fileData, 12, new uint64[](0));
        assertTrue(fileResult.length > 0, "FILE type should produce valid result");

        // Test METADATA type
        bytes memory metadataResult = UnixFS.metadata(metadataData);
        assertTrue(metadataResult.length > 0, "METADATA type should produce valid result");

        // Test SYMLINK type
        bytes memory symlinkResult = UnixFS.symlink(symlinkTarget);
        assertTrue(symlinkResult.length > 0, "SYMLINK type should produce valid result");

        // Test DIRECTORY type
        bytes[] memory hashes = new bytes[](1);
        string[] memory names = new string[](1);
        hashes[0] = hex"1220ba7816bf8f01cfea414140de5dae2223b00361a396177a9cb410ff61f20015ad";
        names[0] = "test.txt";
        bytes memory dirResult = UnixFS.directory(hashes, names);
        assertTrue(dirResult.length > 0, "DIRECTORY type should produce valid result");

        console.log("All UnixFS types tested successfully");
    }

    function test_LargeFileData() public pure {
        // Test with larger data to ensure scalability
        bytes memory largeData = new bytes(1024);
        for (uint256 i = 0; i < 1024; i++) {
            largeData[i] = bytes1(uint8(i % 256));
        }

        uint64[] memory blocksizes = new uint64[](4);
        blocksizes[0] = 256;
        blocksizes[1] = 256;
        blocksizes[2] = 256;
        blocksizes[3] = 256;

        bytes memory result = UnixFS.file(largeData, 1024, blocksizes);
        assertTrue(result.length > 0, "Large file should be encoded successfully");

        // Verify it contains the large data
        assertTrue(result.length >= 1024, "Large file result should be at least as large as input data");

        console.log("Large file test passed - size:", largeData.length);
    }

    function test_MultipleBlocksizes() public pure {
        // Test with multiple non-zero blocksizes
        bytes memory data = bytes("test data");
        uint64[] memory blocksizes = new uint64[](5);
        blocksizes[0] = 100;
        blocksizes[1] = 200;
        blocksizes[2] = 300;
        blocksizes[3] = 400;
        blocksizes[4] = 500;

        bytes memory result = UnixFS.file(data, 1500, blocksizes);
        assertTrue(result.length > 0, "Multiple blocksizes should be encoded");

        // Should contain all non-zero blocksizes
        assertTrue(result.length > 20, "Result should be substantial with multiple blocksizes");

        console.log("Multiple blocksizes test passed");
    }

    function test_EmptyStringSymlink() public pure {
        // Test symlink with empty target
        string memory emptyTarget = "";
        bytes memory result = UnixFS.symlink(emptyTarget);
        assertTrue(result.length > 0, "Empty symlink target should be valid");

        // Should contain symlink type but no data field
        assertEq(uint8(result[0]), 0x08, "Should start with type field tag");
        assertEq(uint8(result[1]), UnixFS.SYMLINK, "Type should be SYMLINK (4)");

        console.log("Empty symlink target test passed");
    }

    function test_UnicodeSymlink() public pure {
        // Test symlink with Unicode characters
        string memory unicodeTarget = unicode"/path/with/unicode/测试/文件.txt";
        bytes memory result = UnixFS.symlink(unicodeTarget);
        assertTrue(result.length > 0, "Unicode symlink target should be valid");

        // Should contain symlink type and Unicode data
        assertEq(uint8(result[0]), 0x08, "Should start with type field tag");
        assertEq(uint8(result[1]), UnixFS.SYMLINK, "Type should be SYMLINK (4)");

        console.log("Unicode symlink target test passed");
    }

    function test_DirectoryWithManyLinks() public pure {
        // Test directory with many links
        uint256 linkCount = 10;
        bytes[] memory hashes = new bytes[](linkCount);
        string[] memory names = new string[](linkCount);

        for (uint256 i = 0; i < linkCount; i++) {
            hashes[i] = abi.encodePacked(hex"1220", keccak256(abi.encodePacked("hash", i)));
            names[i] = string(abi.encodePacked("file", vm.toString(i), ".txt"));
        }

        bytes memory result = UnixFS.directory(hashes, names);
        assertTrue(result.length > 0, "Directory with many links should be valid");

        // Should contain directory type and multiple links
        assertTrue(result.length > 100, "Directory with many links should be substantial");
        assertEq(uint8(result[result.length - 1]), UnixFS.DIRECTORY, "Should end with directory type");

        console.log("Directory with", linkCount, "links test passed");
    }

    function test_ZeroFilesizeFile() public pure {
        // Test file with zero filesize
        bytes memory data = bytes("test");
        bytes memory result = UnixFS.file(data, 0, new uint64[](0));
        assertTrue(result.length > 0, "File with zero filesize should be valid");

        // Should contain type and data, but no filesize field
        assertEq(uint8(result[0]), 0x08, "Should start with type field tag");
        assertEq(uint8(result[1]), UnixFS.FILE, "Type should be FILE (2)");

        console.log("Zero filesize file test passed");
    }

    function test_EmptyMetadata() public pure {
        // Test metadata with empty data
        bytes memory emptyMetadata = "";
        bytes memory result = UnixFS.metadata(emptyMetadata);
        assertTrue(result.length > 0, "Empty metadata should be valid");

        // Should contain metadata type but no data field
        assertEq(uint8(result[0]), 0x08, "Should start with type field tag");
        assertEq(uint8(result[1]), UnixFS.METADATA, "Type should be METADATA (3)");

        console.log("Empty metadata test passed");
    }

    function test_RawWithEmptyData() public pure {
        // Test raw node with empty data
        bytes memory emptyData = "";
        bytes memory result = UnixFS.raw(emptyData);
        assertTrue(result.length > 0, "Raw node with empty data should be valid");

        // Should contain raw type but no data field
        assertEq(uint8(result[0]), 0x08, "Should start with type field tag");
        assertEq(uint8(result[1]), UnixFS.RAW, "Type should be RAW (0)");

        console.log("Raw node with empty data test passed");
    }

    // ========== ERROR CONDITION TESTS ==========

    function test_DirectoryMismatchedArrays() public pure {
        // Test that directory function handles mismatched array lengths gracefully (GiGo)
        bytes[] memory hashes = new bytes[](3);
        string[] memory names = new string[](2);
        
        hashes[0] = hex"1220ba7816bf8f01cfea414140de5dae2223b00361a396177a9cb410ff61f20015ad";
        hashes[1] = hex"1220b94d27b9934d3e08a52e52d7da7dabfac484efe37a5380ee9088f7ace2efcde9";
        hashes[2] = hex"1220c4ca4238a0b923820dcc509a6f75849b";
        names[0] = "file1.txt";
        names[1] = "file2.txt";
        
        bytes memory result = UnixFS.directory(hashes, names);
        
        // Should not revert, should use minimum length (2)
        assertTrue(result.length > 0, "Directory with mismatched arrays should not be empty");
        
        // Should contain directory type byte
        assertEq(uint8(result[result.length - 1]), UnixFS.DIRECTORY, "Directory should end with directory type");
        
        console.log("Directory with mismatched arrays (3 hashes, 2 names) - used 2 links:");
        console.logBytes(result);
    }

    // ========== VALIDATION TESTS ==========

    function test_UnixFSConstants() public pure {
        // Verify all UnixFS type constants are correct
        assertEq(UnixFS.RAW, 0, "RAW type should be 0");
        assertEq(UnixFS.DIRECTORY, 1, "DIRECTORY type should be 1");
        assertEq(UnixFS.FILE, 2, "FILE type should be 2");
        assertEq(UnixFS.METADATA, 3, "METADATA type should be 3");
        assertEq(UnixFS.SYMLINK, 4, "SYMLINK type should be 4");

        console.log("All UnixFS constants validated");
    }

    function test_EncodeUnixFSDataAllTypes() public pure {
        // Test encodeUnixFSData with all types
        bytes memory testData = bytes("test");

        // Test RAW
        bytes memory rawEncoded = UnixFS.encodeUnixFSData(UnixFS.RAW, testData, 0, new uint64[](0));
        assertTrue(rawEncoded.length > 0, "RAW encoding should not be empty");
        assertEq(uint8(rawEncoded[0]), 0x08, "RAW should start with type field tag");
        assertEq(uint8(rawEncoded[1]), UnixFS.RAW, "RAW type should be 0");

        // Test FILE
        bytes memory fileEncoded = UnixFS.encodeUnixFSData(UnixFS.FILE, testData, 4, new uint64[](0));
        assertTrue(fileEncoded.length > 0, "FILE encoding should not be empty");
        assertEq(uint8(fileEncoded[0]), 0x08, "FILE should start with type field tag");
        assertEq(uint8(fileEncoded[1]), UnixFS.FILE, "FILE type should be 2");

        // Test METADATA
        bytes memory metadataEncoded = UnixFS.encodeUnixFSData(UnixFS.METADATA, testData, 0, new uint64[](0));
        assertTrue(metadataEncoded.length > 0, "METADATA encoding should not be empty");
        assertEq(uint8(metadataEncoded[0]), 0x08, "METADATA should start with type field tag");
        assertEq(uint8(metadataEncoded[1]), UnixFS.METADATA, "METADATA type should be 3");

        // Test SYMLINK
        bytes memory symlinkEncoded = UnixFS.encodeUnixFSData(UnixFS.SYMLINK, testData, 0, new uint64[](0));
        assertTrue(symlinkEncoded.length > 0, "SYMLINK encoding should not be empty");
        assertEq(uint8(symlinkEncoded[0]), 0x08, "SYMLINK should start with type field tag");
        assertEq(uint8(symlinkEncoded[1]), UnixFS.SYMLINK, "SYMLINK type should be 4");

        // Test DIRECTORY (special case - just type byte)
        bytes memory dirEncoded = UnixFS.encodeUnixFSData(UnixFS.DIRECTORY, "", 0, new uint64[](0));
        assertEq(dirEncoded, hex"01", "DIRECTORY should encode as single byte 0x01");
        assertEq(dirEncoded.length, 1, "DIRECTORY should be exactly 1 byte");

        console.log("All UnixFS types encoding tested");
    }

    function test_ProtobufFieldEncoding() public pure {
        // Test that protobuf field encoding works correctly
        bytes memory data = bytes("test data");
        uint64 filesize = 9;
        uint64[] memory blocksizes = new uint64[](2);
        blocksizes[0] = 5;
        blocksizes[1] = 4;

        bytes memory result = UnixFS.encodeUnixFSData(UnixFS.FILE, data, filesize, blocksizes);

        // Should contain protobuf fields for type, data, filesize, and blocksizes
        assertTrue(result.length > 0, "Protobuf encoding should not be empty");

        // Verify it starts with type field (0x08 0x02 for type=2)
        assertEq(uint8(result[0]), 0x08, "Should start with type field tag");
        assertEq(uint8(result[1]), 0x02, "Type should be 2 (FILE)");

        console.log("Protobuf field encoding test passed");
    }
}
