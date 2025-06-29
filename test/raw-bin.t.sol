// SPDX-License-Identifier: WTFPL.ETH
pragma solidity ^0.8.0;

import "forge-std/Test.sol";
import {Raw} from "../src/multiformats/multicodec/raw-bin.sol";
import {Varint} from "../src/multiformats/varint.sol";
import {TestHelpers} from "./TestHelpers.sol";

contract RawBinTest is Test {
    using Varint for uint256;

    // ========== BASIC ENCODING TESTS ==========

    function test_Raw() public pure {
        bytes memory data = bytes("Hello World");
        bytes memory result = Raw.encode(data);

        // Full expected: 0x0155000b48656c6c6f20576f726c64
        bytes memory expected = hex"0155000b48656c6c6f20576f726c64";
        assertEq(result, expected, "RAW encode output should match expected");
    }

    function test_RawSha256() public pure {
        bytes memory data = bytes("Hello World");
        bytes memory result = Raw.encodeSha256(data);

        // Expected: 0x01551220 + SHA256 hash of the data
        bytes memory expected = abi.encodePacked(hex"01551220", sha256(data));
        assertEq(result, expected, "RAW SHA256 output should match expected");
    }

    function test_RawKeccak256() public pure {
        bytes memory data = bytes("Hello World");
        bytes memory result = Raw.encodeKeccak256(data);

        // Expected: 0x01551b20 + Keccak256 hash of the data
        bytes memory expected = abi.encodePacked(hex"01551b20", keccak256(data));
        assertEq(result, expected, "RAW Keccak256 output should match expected");
    }

    // ========== ENCODE FUNCTION TESTS ==========

    function test_EncodeWithRaw() public pure {
        bytes memory data = bytes("Hello World");

        // Test with encode as encoder (redundant but for consistency)
        bytes memory result = Raw.encode(data);

        // Should be same as encode
        bytes memory expected = Raw.encode(data);
        assertEq(result, expected, "encode should equal encode");

        console.log("Encode with raw result:");
        console.logBytes(result);
    }

    function test_EncodeWithRawSha256() public pure {
        bytes memory data = bytes("Hello World");

        // Test with encodeSha256 as encoder (redundant but for consistency)
        bytes memory result = Raw.encodeSha256(data);

        // Should be same as encodeSha256
        bytes memory expected = Raw.encodeSha256(data);
        assertEq(result, expected, "encodeSha256 should equal encodeSha256");

        console.log("Encode with raw SHA256 result:");
        console.logBytes(result);
    }

    function test_EncodeWithRawKeccak256() public pure {
        bytes memory data = bytes("Hello World");

        // Test with encodeKeccak256 as encoder (redundant but for consistency)
        bytes memory result = Raw.encodeKeccak256(data);

        // Should be same as encodeKeccak256
        bytes memory expected = Raw.encodeKeccak256(data);
        assertEq(result, expected, "encodeKeccak256 should equal encodeKeccak256");

        console.log("Encode with raw Keccak256 result:");
        console.logBytes(result);
    }

    // ========== EDGE CASES ==========

    function test_EmptyData() public pure {
        bytes memory emptyData = "";
        bytes memory result = Raw.encode(emptyData);

        // Expected: 0x01550000
        bytes memory expected = hex"01550000";
        assertEq(result, expected, "RAW encode output for empty data should match expected");
    }

    function test_LargeData() public pure {
        bytes memory largeData = new bytes(1024);
        for (uint256 i = 0; i < 1024; i++) {
            largeData[i] = bytes1(uint8(i % 256));
        }

        bytes memory result = Raw.encode(largeData);

        assertTrue(result.length > 0, "Large data should be encoded");
        assertTrue(result.length >= largeData.length, "Result should be at least as large as input");

        console.log("Large data test passed - size:", largeData.length);
    }

    function test_SingleByteData() public pure {
        bytes memory singleByte = hex"41"; // "A"
        bytes memory result = Raw.encode(singleByte);

        assertTrue(result.length > 0, "Single byte should be encoded");
        assertTrue(result.length >= 5, "Should contain prefix + varint + data");

        console.log("Single byte result:");
        console.logBytes(result);
    }

    // ========== HASH VERIFICATION ==========

    function test_Sha256HashCorrectness() public pure {
        bytes memory data = bytes("Hello World");
        bytes memory result = Raw.encodeSha256(data);

        // Extract the hash from the result (skip prefix)
        bytes memory hash = new bytes(32);
        for (uint256 i = 0; i < 32; i++) {
            hash[i] = result[4 + i]; // Skip 4-byte prefix
        }

        // Verify it matches the expected SHA256 hash
        bytes32 expectedHash = sha256(data);
        assertEq(bytes32(hash), expectedHash, "SHA256 hash should be correct");

        console.log("SHA256 hash verification passed");
    }

    function test_Keccak256HashCorrectness() public pure {
        bytes memory data = bytes("Hello World");
        bytes memory result = Raw.encodeKeccak256(data);

        // Extract the hash from the result (skip prefix)
        bytes memory hash = new bytes(32);
        for (uint256 i = 0; i < 32; i++) {
            hash[i] = result[4 + i]; // Skip 4-byte prefix
        }

        // Verify it matches the expected Keccak256 hash
        bytes32 expectedHash = keccak256(data);
        assertEq(bytes32(hash), expectedHash, "Keccak256 hash should be correct");

        console.log("Keccak256 hash verification passed");
    }

    // ========== VARINT LENGTH TESTS ==========

    function test_VarintLengthEncoding() public pure {
        bytes memory data = bytes("test");
        bytes memory result = Raw.encode(data);

        // Should contain varint-encoded length after prefix
        assertTrue(result.length > 4, "Should contain length after prefix");

        // Extract and verify varint length
        uint256 offset = 3 + 1; // 3 bytes prefix + 1 for varint start
        (uint256 decodedLength,) = TestHelpers.decodeVarint(result, 3);
        assertEq(decodedLength, data.length, "Varint length should match data length");

        console.log("Varint length encoding test passed");
    }

    // ========== PREFIX VALIDATION ==========

    function test_RawPrefix() public pure {
        bytes memory data = bytes("test");
        bytes memory result = Raw.encode(data);

        // Verify raw prefix: 0x015500
        assertEq(uint8(result[0]), 0x01, "Raw prefix byte 0 should be 0x01");
        assertEq(uint8(result[1]), 0x55, "Raw prefix byte 1 should be 0x55");
        assertEq(uint8(result[2]), 0x00, "Raw prefix byte 2 should be 0x00");

        console.log("Raw prefix validation passed");
    }

    function test_Sha256Prefix() public pure {
        bytes memory data = bytes("test");
        bytes memory result = Raw.encodeSha256(data);

        // Verify SHA256 prefix: 0x01551220
        assertEq(uint8(result[0]), 0x01, "SHA256 prefix byte 0 should be 0x01");
        assertEq(uint8(result[1]), 0x55, "SHA256 prefix byte 1 should be 0x55");
        assertEq(uint8(result[2]), 0x12, "SHA256 prefix byte 2 should be 0x12");
        assertEq(uint8(result[3]), 0x20, "SHA256 prefix byte 3 should be 0x20");

        console.log("SHA256 prefix validation passed");
    }

    function test_Keccak256Prefix() public pure {
        bytes memory data = bytes("test");
        bytes memory result = Raw.encodeKeccak256(data);

        // Verify Keccak256 prefix: 0x01551b20
        assertEq(uint8(result[0]), 0x01, "Keccak256 prefix byte 0 should be 0x01");
        assertEq(uint8(result[1]), 0x55, "Keccak256 prefix byte 1 should be 0x55");
        assertEq(uint8(result[2]), 0x1b, "Keccak256 prefix byte 2 should be 0x1b");
        assertEq(uint8(result[3]), 0x20, "Keccak256 prefix byte 3 should be 0x20");

        console.log("Keccak256 prefix validation passed");
    }

    // ========== COMPREHENSIVE TESTS ==========

    function test_AllRawFunctions() public pure {
        bytes memory data = bytes("Hello World");

        // Test all raw functions
        bytes memory rawResult = Raw.encode(data);
        bytes memory sha256Result = Raw.encodeSha256(data);
        bytes memory keccak256Result = Raw.encodeKeccak256(data);

        // All should produce results
        assertTrue(rawResult.length > 0, "Raw should produce result");
        assertTrue(sha256Result.length > 0, "Raw SHA256 should produce result");
        assertTrue(keccak256Result.length > 0, "Raw Keccak256 should produce result");

        // Verify different lengths
        assertTrue(rawResult.length > 4, "Raw should be longer than prefix");
        assertEq(sha256Result.length, 36, "Raw SHA256 should be 36 bytes (4 + 32)");
        assertEq(keccak256Result.length, 36, "Raw Keccak256 should be 36 bytes (4 + 32)");

        console.log("All raw functions tested successfully");
    }

    function test_UnicodeData() public pure {
        bytes memory unicodeData = bytes(unicode"Hello 世界");
        bytes memory result = Raw.encode(unicodeData);

        assertTrue(result.length > 0, "Unicode data should be encoded");
        assertTrue(result.length >= unicodeData.length, "Result should be at least as large as input");

        console.log("Unicode data test passed");
    }

    function test_BinaryData() public pure {
        bytes memory binaryData = hex"0102030405060708090a0b0c0d0e0f";
        bytes memory result = Raw.encode(binaryData);

        assertTrue(result.length > 0, "Binary data should be encoded");
        assertTrue(result.length >= binaryData.length, "Result should be at least as large as input");

        console.log("Binary data test passed");
    }
}
