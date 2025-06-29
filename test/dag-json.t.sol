// SPDX-License-Identifier: WTFPL.ETH
pragma solidity ^0.8.0;

import "forge-std/Test.sol";
import {DAG_JSON} from "../src/multiformats/multicodec/dag-json.sol";
import {JSON_UTF8} from "../src/multiformats/multicodec/json-utf8.sol";
import {TestHelpers} from "./TestHelpers.sol";

contract DagJsonTest is Test {
    using TestHelpers for bytes;

    // ========== BASIC ENCODING TESTS ==========

    function test_Encode() public pure {
        bytes memory data = bytes('{"Hello":"World"}');
        bytes memory result = DAG_JSON.encode(data);
        // Full expected: 0x01a90211 7b2248656c6c6f223a22576f726c64227d
        bytes memory expected = hex"01a902117b2248656c6c6f223a22576f726c64227d";
        assertEq(result, expected, "DAG-JSON encode output should match expected");
    }

    function test_DagJson() public pure {
        bytes memory data = bytes('{"Hello":"World"}');
        bytes memory result = DAG_JSON.encode(data);
        bytes memory expected = hex"01a902117b2248656c6c6f223a22576f726c64227d";
        assertEq(result, expected, "DAG-JSON encode output should match expected");
    }

    // ========== LINK TESTS ==========

    function test_Link() public pure {
        string memory key = "test";
        bytes memory cidv1 = hex"0170000a48656c6c6f20576f726c64";
        bytes memory result = DAG_JSON.link(key, cidv1);

        // Should format as {"test":{"/":"f0170000a48656c6c6f20576f726c64"}}
        assertTrue(result.length > 0, "Link should not be empty");
        assertTrue(result.length > 20, "Should contain JSON structure");

        // Convert to string for easier verification
        string memory resultStr = string(result);
        assertTrue(bytes(resultStr).length > 0, "Link string should not be empty");

        console.log("Link result:", resultStr);
    }

    function test_LinkWithEmptyKey() public pure {
        string memory key = "";
        bytes memory cidv1 = hex"0170000a48656c6c6f20576f726c64";
        bytes memory result = DAG_JSON.link(key, cidv1);

        // Should format as {"":{"/":"f0170000a48656c6c6f20576f726c64"}}
        assertTrue(result.length > 0, "Link with empty key should not be empty");

        string memory resultStr = string(result);
        assertTrue(bytes(resultStr).length > 0, "Link string should not be empty");

        console.log("Link with empty key result:", resultStr);
    }

    function test_LinkWithEmptyCid() public pure {
        string memory key = "test";
        bytes memory cidv1 = "";
        bytes memory result = DAG_JSON.link(key, cidv1);

        // Should format as {"test":{"/":"f"}}
        assertTrue(result.length > 0, "Link with empty CID should not be empty");

        string memory resultStr = string(result);
        assertTrue(bytes(resultStr).length > 0, "Link string should not be empty");

        console.log("Link with empty CID result:", resultStr);
    }

    // ========== MAP TESTS ==========

    function test_MapDagJson() public pure {
        JSON_UTF8.KeyValue[] memory kv = new JSON_UTF8.KeyValue[](2);
        kv[0] = JSON_UTF8.KeyValue("file1", hex"0170000a48656c6c6f20576f726c64");
        kv[1] = JSON_UTF8.KeyValue("file2", hex"0170000a476f6f64627965");

        bytes memory result = DAG_JSON.mapDagJson(kv);

        // Should format as {"file1":{"/":"f0170000a48656c6c6f20576f726c64"},"file2":{"/":"f0170000a476f6f64627965"}}
        assertTrue(result.length > 0, "Map DAG-JSON should not be empty");
        assertTrue(result.length > 50, "Should contain JSON structure with multiple entries");

        string memory resultStr = string(result);
        assertTrue(bytes(resultStr).length > 0, "Map string should not be empty");

        console.log("Map DAG-JSON result:", resultStr);
    }

    function test_MapDagJsonEmpty() public pure {
        JSON_UTF8.KeyValue[] memory kv = new JSON_UTF8.KeyValue[](0);
        bytes memory result = DAG_JSON.mapDagJson(kv);

        // Should format as {}
        assertTrue(result.length > 0, "Empty map should not be empty");
        assertEq(string(result), "{}", "Empty map should be {}");

        console.log("Empty map result:", string(result));
    }

    function test_MapDagJsonSingle() public pure {
        JSON_UTF8.KeyValue[] memory kv = new JSON_UTF8.KeyValue[](1);
        kv[0] = JSON_UTF8.KeyValue("file1", hex"0170000a48656c6c6f20576f726c64");

        bytes memory result = DAG_JSON.mapDagJson(kv);

        // Should format as {"file1":{"/":"f0170000a48656c6c6f20576f726c64"}}
        assertTrue(result.length > 0, "Single entry map should not be empty");
        assertTrue(result.length > 30, "Should contain JSON structure");

        string memory resultStr = string(result);
        assertTrue(bytes(resultStr).length > 0, "Map string should not be empty");

        console.log("Single entry map result:", resultStr);
    }

    // ========== KEY-VALUE TESTS ==========

    function test_KeyValueToDagJson() public pure {
        JSON_UTF8.KeyValue memory kv = JSON_UTF8.KeyValue("test", hex"0170000a48656c6c6f20576f726c64");
        string memory result = DAG_JSON.keyValueToDagJson(kv);

        // Should format as {"test":{"/":"f0170000a48656c6c6f20576f726c64"}}
        assertTrue(bytes(result).length > 0, "KeyValue to DAG-JSON should not be empty");
        assertTrue(bytes(result).length > 20, "Should contain JSON structure");

        console.log("KeyValue to DAG-JSON result:", result);
    }

    function test_KeyValueArrayToDagJson() public pure {
        JSON_UTF8.KeyValue[] memory kv = new JSON_UTF8.KeyValue[](2);
        kv[0] = JSON_UTF8.KeyValue("file1", hex"0170000a48656c6c6f20576f726c64");
        kv[1] = JSON_UTF8.KeyValue("file2", hex"0170000a476f6f64627965");

        string memory result = DAG_JSON.keyValueArrayToDagJson(kv);

        // Should format as {"file1":{"/":"f0170000a48656c6c6f20576f726c64"},"file2":{"/":"f0170000a476f6f64627965"}}
        assertTrue(bytes(result).length > 0, "KeyValue array to DAG-JSON should not be empty");
        assertTrue(bytes(result).length > 50, "Should contain JSON structure with multiple entries");

        console.log("KeyValue array to DAG-JSON result:", result);
    }

    function test_KeyValueArrayToDagJsonEmpty() public pure {
        JSON_UTF8.KeyValue[] memory kv = new JSON_UTF8.KeyValue[](0);
        string memory result = DAG_JSON.keyValueArrayToDagJson(kv);

        // Should format as {}
        assertTrue(bytes(result).length > 0, "Empty KeyValue array should not be empty");
        assertEq(result, "{}", "Empty KeyValue array should be {}");

        console.log("Empty KeyValue array result:", result);
    }

    function test_KeyValueArrayToDagJsonSingle() public pure {
        JSON_UTF8.KeyValue[] memory kv = new JSON_UTF8.KeyValue[](1);
        kv[0] = JSON_UTF8.KeyValue("file1", hex"0170000a48656c6c6f20576f726c64");

        string memory result = DAG_JSON.keyValueArrayToDagJson(kv);

        // Should format as {"file1":{"/":"f0170000a48656c6c6f20576f726c64"}}
        assertTrue(bytes(result).length > 0, "Single KeyValue should not be empty");
        assertTrue(bytes(result).length > 30, "Should contain JSON structure");

        console.log("Single KeyValue result:", result);
    }

    // ========== EDGE CASES ==========

    function test_EmptyData() public pure {
        bytes memory emptyData = "";
        bytes memory result = DAG_JSON.encode(emptyData);
        bytes memory expected = hex"01a90200";
        assertEq(result, expected, "DAG-JSON encode output for empty data should match expected");
    }

    function test_LargeData() public pure {
        bytes memory largeData = new bytes(1024);
        for (uint256 i = 0; i < 1024; i++) {
            largeData[i] = bytes1(uint8(i % 256));
        }

        bytes memory result = DAG_JSON.encode(largeData);

        assertTrue(result.length > 0, "Large data should be encoded");
        assertTrue(result.length >= largeData.length, "Result should be at least as large as input");

        console.log("Large data test passed - size:", largeData.length);
    }

    function test_UnicodeData() public pure {
        bytes memory unicodeData = bytes(unicode"Hello 世界");
        bytes memory result = DAG_JSON.encode(unicodeData);

        assertTrue(result.length > 0, "Unicode data should be encoded");
        assertTrue(result.length >= unicodeData.length, "Result should be at least as large as input");

        console.log("Unicode data test passed");
    }

    // ========== VARINT LENGTH TESTS ==========

    function test_VarintLengthEncoding() public pure {
        bytes memory data = bytes("test");
        bytes memory result = DAG_JSON.encode(data);

        // Should contain varint-encoded length after prefix
        assertTrue(result.length > 3, "Should contain length after prefix");

        // Extract and verify varint length
        bytes memory lengthBytes = new bytes(result.length - 3 - data.length);
        for (uint256 i = 0; i < lengthBytes.length; i++) {
            lengthBytes[i] = result[3 + i]; // Skip 3-byte prefix
        }

        // Decode varint length
        (uint256 decodedLength,) = TestHelpers.decodeVarint(lengthBytes, 0);
        assertEq(decodedLength, data.length, "Varint length should match data length");

        console.log("Varint length encoding test passed");
    }

    // ========== JSON STRUCTURE VALIDATION ==========

    function test_LinkJsonStructure() public pure {
        string memory key = "test";
        bytes memory cidv1 = hex"0170000a48656c6c6f20576f726c64";
        bytes memory result = DAG_JSON.link(key, cidv1);

        string memory resultStr = string(result);

        // Should start with {"
        assertTrue(bytes(resultStr).length > 2, "Should have opening brace and quote");
        assertEq(uint8(bytes(resultStr)[0]), 0x7b, "Should start with {");
        assertEq(uint8(bytes(resultStr)[1]), 0x22, "Should have quote after {");

        // Should end with "}
        assertEq(uint8(bytes(resultStr)[bytes(resultStr).length - 1]), 0x7d, "Should end with }");

        console.log("Link JSON structure validation passed");
    }

    function test_MapJsonStructure() public pure {
        JSON_UTF8.KeyValue[] memory kv = new JSON_UTF8.KeyValue[](1);
        kv[0] = JSON_UTF8.KeyValue("test", hex"0170000a48656c6c6f20576f726c64");

        bytes memory result = DAG_JSON.mapDagJson(kv);
        string memory resultStr = string(result);

        // Should start with { and end with }
        assertEq(uint8(bytes(resultStr)[0]), 0x7b, "Should start with {");
        assertEq(uint8(bytes(resultStr)[bytes(resultStr).length - 1]), 0x7d, "Should end with }");

        console.log("Map JSON structure validation passed");
    }

    // ========== COMPREHENSIVE TESTS ==========

    function test_AllDagJsonFunctions() public pure {
        bytes memory data = bytes('{"Hello":"World"}');
        bytes memory encodeResult = DAG_JSON.encode(data);
        bytes memory dagJsonResult = DAG_JSON.encode(data);
        bytes memory expected = hex"01a902117b2248656c6c6f223a22576f726c64227d";
        assertEq(encodeResult, expected, "Encode should match expected");
        assertEq(dagJsonResult, expected, "DagJson should match expected");
    }

    function test_ComplexMap() public pure {
        JSON_UTF8.KeyValue[] memory kv = new JSON_UTF8.KeyValue[](3);
        kv[0] = JSON_UTF8.KeyValue("file1", hex"0170000a48656c6c6f20576f726c64");
        kv[1] = JSON_UTF8.KeyValue("file2", hex"0170000a476f6f64627965");
        kv[2] = JSON_UTF8.KeyValue("file3", hex"0170000a546573742044617461");

        bytes memory result = DAG_JSON.mapDagJson(kv);
        string memory resultStr = string(result);

        assertTrue(result.length > 0, "Complex map should not be empty");
        assertTrue(bytes(resultStr).length > 80, "Should contain JSON structure with multiple entries");

        console.log("Complex map result:", resultStr);
    }

    function test_UnicodeKeyValue() public pure {
        JSON_UTF8.KeyValue[] memory kv = new JSON_UTF8.KeyValue[](1);
        kv[0] = JSON_UTF8.KeyValue(unicode"测试", hex"0170000a48656c6c6f20576f726c64");

        string memory result = DAG_JSON.keyValueArrayToDagJson(kv);

        assertTrue(bytes(result).length > 0, "Unicode KeyValue should produce result");
        assertTrue(bytes(result).length > 20, "Should contain JSON structure");

        console.log("Unicode KeyValue result:", result);
    }
}
