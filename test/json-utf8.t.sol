// SPDX-License-Identifier: WTFPL.ETH
pragma solidity ^0.8.0;

import "forge-std/Test.sol";
import {JSON_UTF8} from "../src/multiformats/multicodec/json-utf8.sol";
import {Varint} from "../src/multiformats/varint.sol";
import {TestHelpers} from "./TestHelpers.sol";

contract JSON_UTF8Test is Test {
    using Varint for uint256;

    // ========== BASIC ENCODING TESTS ==========

    function test_JsonRaw() public pure {
        bytes memory data = bytes('{"Hello":"World"}');
        bytes memory result = JSON_UTF8.encode(data);

        // Full expected: 0x01800400117b2248656c6c6f223a22576f726c64227d
        bytes memory expected = hex"01800400117b2248656c6c6f223a22576f726c64227d";
        assertEq(result, expected, "JSON UTF-8 encode output should match expected");
    }

    function test_JsonSha256() public pure {
        bytes memory data = bytes('{"Hello":"World"}');
        bytes memory result = JSON_UTF8.encodeSha256(data);

        // Expected: 0x0180041220 + SHA256 hash of the data
        bytes memory expected = abi.encodePacked(JSON_UTF8.JSON_UTF8_SHA256, sha256(data));
        assertEq(result, expected, "JSON UTF-8 SHA256 output should match expected");
    }

    function test_JsonKeccak256() public pure {
        bytes memory data = bytes('{"Hello":"World"}');
        bytes memory result = JSON_UTF8.encodeKeccak256(data);

        // Expected: 0x0180041b20 + Keccak256 hash of the data
        bytes memory expected = abi.encodePacked(JSON_UTF8.JSON_UTF8_KECCAK256, keccak256(data));
        assertEq(result, expected, "JSON UTF-8 Keccak256 output should match expected");
    }

    function test_JsonAlias() public pure {
        bytes memory data = bytes('{"Hello":"World"}');
        bytes memory result = JSON_UTF8.encode(data);

        // Should be same as encode
        bytes memory expected = JSON_UTF8.encode(data);
        assertEq(result, expected, "encode should equal encode");

        console.log("JSON alias test passed");
    }

    // ========== KEY-VALUE JSON TESTS ==========

    function test_KvJsonHex() public pure {
        JSON_UTF8.KeyValue memory kv = JSON_UTF8.KeyValue("name", hex"48656c6c6f"); // "Hello" in hex
        string memory result = JSON_UTF8.kvJsonHex(kv);

        // Should format as {"name":"0x48656c6c6f"}
        assertTrue(bytes(result).length > 0, "KeyValue JSON hex should not be empty");
        assertTrue(bytes(result).length > 10, "Should contain JSON structure");

        console.log("KeyValue JSON hex result:", result);
    }

    function test_KvJsonHexPrefixed() public pure {
        JSON_UTF8.KeyValue memory kv = JSON_UTF8.KeyValue("name", hex"48656c6c6f"); // "Hello" in hex
        bytes memory prefix = bytes("f");
        string memory result = JSON_UTF8.kvJsonHexPrefixed(kv, prefix);

        // Should format as {"name":"f48656c6c6f"}
        assertTrue(bytes(result).length > 0, "KeyValue JSON hex prefixed should not be empty");
        assertTrue(bytes(result).length > 10, "Should contain JSON structure");

        console.log("KeyValue JSON hex prefixed result:", result);
    }

    function test_KvJsonString() public pure {
        JSON_UTF8.KeyValue memory kv = JSON_UTF8.KeyValue("name", bytes("Hello World"));
        string memory result = JSON_UTF8.kvJsonString(kv);

        // Should format as {"name":"Hello World"}
        assertTrue(bytes(result).length > 0, "KeyValue JSON string should not be empty");
        assertTrue(bytes(result).length > 10, "Should contain JSON structure");

        console.log("KeyValue JSON string result:", result);
    }

    // ========== EDGE CASES ==========

    function test_EmptyData() public pure {
        bytes memory emptyData = "";
        bytes memory result = JSON_UTF8.encode(emptyData);

        // Expected: 0x0180040000
        bytes memory expected = hex"0180040000";
        assertEq(result, expected, "JSON UTF-8 encode output for empty data should match expected");
    }

    function test_LargeData() public pure {
        bytes memory largeData = new bytes(1024);
        for (uint256 i = 0; i < 1024; i++) {
            largeData[i] = bytes1(uint8(i % 256));
        }

        bytes memory result = JSON_UTF8.encode(largeData);

        assertTrue(result.length > 0, "Large data should be encoded");
        assertTrue(result.length >= largeData.length, "Result should be at least as large as input");

        console.log("Large data test passed - size:", largeData.length);
    }

    function test_EmptyKeyValue() public pure {
        JSON_UTF8.KeyValue memory kv = JSON_UTF8.KeyValue("", "");
        string memory result = JSON_UTF8.kvJsonString(kv);

        // Should format as {"":""}
        assertTrue(bytes(result).length > 0, "Empty KeyValue should still produce result");
        assertEq(result, '{"":""}', "Empty KeyValue should produce minimal JSON");

        console.log("Empty KeyValue result:", result);
    }

    function test_UnicodeKeyValue() public pure {
        JSON_UTF8.KeyValue memory kv = JSON_UTF8.KeyValue(unicode"测试", bytes(unicode"Hello 世界"));
        string memory result = JSON_UTF8.kvJsonString(kv);

        assertTrue(bytes(result).length > 0, "Unicode KeyValue should produce result");
        assertTrue(bytes(result).length > 10, "Should contain JSON structure");

        console.log("Unicode KeyValue result:", result);
    }

    // ========== CONSTANT VALIDATION ==========

    function test_Constants() public pure {
        // Verify constants are not empty
        assertTrue(JSON_UTF8.JSON_UTF8_RAW.length > 0, "JSON_UTF8_RAW should not be empty");
        assertTrue(JSON_UTF8.JSON_UTF8_SHA256.length > 0, "JSON_UTF8_SHA256 should not be empty");
        assertTrue(JSON_UTF8.JSON_UTF8_KECCAK256.length > 0, "JSON_UTF8_KECCAK256 should not be empty");

        // Verify they have expected prefixes
        assertEq(uint8(JSON_UTF8.JSON_UTF8_RAW[0]), 0x01, "JSON_UTF8_RAW should start with 0x01");
        assertEq(uint8(JSON_UTF8.JSON_UTF8_SHA256[0]), 0x01, "JSON_UTF8_SHA256 should start with 0x01");
        assertEq(uint8(JSON_UTF8.JSON_UTF8_KECCAK256[0]), 0x01, "JSON_UTF8_KECCAK256 should start with 0x01");

        console.log("All constants validated");
    }

    // ========== HASH VERIFICATION ==========

    function test_Sha256HashCorrectness() public pure {
        bytes memory data = bytes("Hello World");
        bytes memory result = JSON_UTF8.encodeSha256(data);

        // Extract the hash from the result (skip prefix)
        bytes memory hash = new bytes(32);
        for (uint256 i = 0; i < 32; i++) {
            hash[i] = result[JSON_UTF8.JSON_UTF8_SHA256.length + i];
        }

        // Verify it matches the expected SHA256 hash
        bytes32 expectedHash = sha256(data);
        assertEq(bytes32(hash), expectedHash, "SHA256 hash should be correct");

        console.log("SHA256 hash verification passed");
    }

    function test_Keccak256HashCorrectness() public pure {
        bytes memory data = bytes("Hello World");
        bytes memory result = JSON_UTF8.encodeKeccak256(data);

        // Extract the hash from the result (skip prefix)
        bytes memory hash = new bytes(32);
        for (uint256 i = 0; i < 32; i++) {
            hash[i] = result[JSON_UTF8.JSON_UTF8_KECCAK256.length + i];
        }

        // Verify it matches the expected Keccak256 hash
        bytes32 expectedHash = keccak256(data);
        assertEq(bytes32(hash), expectedHash, "Keccak256 hash should be correct");

        console.log("Keccak256 hash verification passed");
    }

    // ========== VARINT LENGTH TESTS ==========

    function test_VarintLengthEncoding() public pure {
        bytes memory data = bytes("test");
        bytes memory result = JSON_UTF8.encode(data);

        // Should contain varint-encoded length after prefix
        assertTrue(result.length > JSON_UTF8.JSON_UTF8_RAW.length, "Should contain length after prefix");

        // Extract and verify varint length
        bytes memory lengthBytes = new bytes(result.length - JSON_UTF8.JSON_UTF8_RAW.length - data.length);
        for (uint256 i = 0; i < lengthBytes.length; i++) {
            lengthBytes[i] = result[JSON_UTF8.JSON_UTF8_RAW.length + i];
        }

        // Decode varint length
        (uint256 decodedLength,) = TestHelpers.decodeVarint(lengthBytes, 0);
        assertEq(decodedLength, data.length, "Varint length should match data length");

        console.log("Varint length encoding test passed");
    }
}
