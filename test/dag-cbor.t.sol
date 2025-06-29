// SPDX-License-Identifier: WTFPL.ETH
pragma solidity ^0.8.0;

import "forge-std/Test.sol";
import {DAG_CBOR} from "../src/multiformats/multicodec/dag-cbor.sol";
import {DAGCBOR_TestData} from "./data/dag-cbor-test-data.sol";
import {Raw} from "../src/multiformats/multicodec/raw-bin.sol";
import {JSON_UTF8} from "../src/multiformats/multicodec/json-utf8.sol";
import {Varint} from "../src/multiformats/varint.sol";
import {UnixFS} from "../src/multiformats/multicodec/unix-fs.sol";
import {TestHelpers} from "./TestHelpers.sol";

contract DagCborTest is Test {
    using Raw for bytes;
    using Varint for uint256;
    using UnixFS for bytes;
    using JSON_UTF8 for bytes;

    // Helper for dag-cbor node: CIDv1 + dag-cbor codec + identity multihash + varint(length) + data
    function _wrapDagCborCID(bytes memory data) internal pure returns (bytes memory) {
        // 0x01 (CIDv1) + 0x71 (dag-cbor codec) + 0x00 (identity multihash) + varint(length) + data
        return abi.encodePacked(bytes1(0x01), bytes1(0x71), bytes1(0x00), data.length.varint(), data);
    }

    function test_RawCIDs() public pure {
        string memory helloWorld = DAGCBOR_TestData.HelloWorld;
        bytes memory rawFile = Raw.encode(bytes(helloWorld));
        bytes memory rawFileSha256 = Raw.encodeSha256(bytes(helloWorld));
        bytes memory rawFileKeccak256 = Raw.encodeKeccak256(bytes(helloWorld));
        assertEq(rawFile, DAGCBOR_TestData.HelloWorldRaw, "Raw identity CID mismatch");
        assertEq(rawFileSha256, DAGCBOR_TestData.HelloWorldRawSha256, "Raw sha256 CID mismatch");
        assertEq(rawFileKeccak256, DAGCBOR_TestData.HelloWorldRawKeccak256, "Raw keccak256 CID mismatch");
    }

    function test_JSONCIDs() public pure {
        bytes memory jsonData = bytes('{"Hello":"World"}');
        bytes memory jsonRaw = JSON_UTF8.encode(jsonData);
        bytes memory jsonSha256 = JSON_UTF8.encodeSha256(jsonData);
        bytes memory jsonKeccak256 = JSON_UTF8.encodeKeccak256(jsonData);
        assertEq(jsonRaw, DAGCBOR_TestData.HelloWorldJsonRaw, "JSON identity CID mismatch");
        assertEq(jsonSha256, DAGCBOR_TestData.HelloWorldJsonSha256, "JSON sha256 CID mismatch");
        assertEq(jsonKeccak256, DAGCBOR_TestData.HelloWorldJsonKeccak256, "JSON keccak256 CID mismatch");
    }

    function test_RawDirectory() public pure {
        string memory helloWorld = DAGCBOR_TestData.HelloWorld;
        bytes memory rawFile = Raw.encode(bytes(helloWorld));
        bytes memory rawFileSha256 = Raw.encodeSha256(bytes(helloWorld));
        bytes memory rawFileKeccak256 = Raw.encodeKeccak256(bytes(helloWorld));
        DAG_CBOR.KeyValue[] memory rawDirEntries = new DAG_CBOR.KeyValue[](3);
        rawDirEntries[0] = DAG_CBOR.KeyValue("sha256.txt", rawFileSha256);
        rawDirEntries[1] = DAG_CBOR.KeyValue("identity.txt", rawFile);
        rawDirEntries[2] = DAG_CBOR.KeyValue("keccak256.txt", rawFileKeccak256);
        bytes memory rawDir = DAG_CBOR.mapCbor(rawDirEntries);
        bytes memory actualRawDirCID = _wrapDagCborCID(rawDir);
        assertEq(actualRawDirCID, DAGCBOR_TestData.RawDirCID, "Raw directory CID mismatch");
    }

    function test_RawDirectory2() public pure {
        string memory helloWorld = DAGCBOR_TestData.HelloWorld;
        bytes memory rawFile = Raw.encode(bytes(helloWorld));
        bytes memory rawFileSha256 = Raw.encodeSha256(bytes(helloWorld));
        bytes memory vb = hex"0170000f6170702e756e69737761702e6f7267";
        ///abi.encodePacked(hex"017000", bytes(domain).length.varint(), domain);
        DAG_CBOR.KeyValue[] memory rawDirEntries = new DAG_CBOR.KeyValue[](3);
        rawDirEntries[0] = DAG_CBOR.KeyValue("sha256.txt", rawFileSha256);
        rawDirEntries[1] = DAG_CBOR.KeyValue("identity.txt", rawFile);
        rawDirEntries[2] = DAG_CBOR.KeyValue("vitalik.eth", vb);
        bytes memory rawDir = DAG_CBOR.mapCbor(rawDirEntries);
        bytes memory actualRawDirCID = _wrapDagCborCID(rawDir);
        console.log("Raw directory CID:");
        console.logBytes(actualRawDirCID);
    }

    function test_JSONDirectory() public pure {
        bytes memory jsonData = bytes('{"Hello":"World"}');
        bytes memory jsonRaw = JSON_UTF8.encode(jsonData);
        bytes memory jsonSha256 = JSON_UTF8.encodeSha256(jsonData);
        bytes memory jsonKeccak256 = JSON_UTF8.encodeKeccak256(jsonData);

        DAG_CBOR.KeyValue[] memory jsonDirEntries = new DAG_CBOR.KeyValue[](3);
        jsonDirEntries[0] = DAG_CBOR.KeyValue("sha256.json", jsonSha256);
        jsonDirEntries[1] = DAG_CBOR.KeyValue("identity.json", jsonRaw);
        jsonDirEntries[2] = DAG_CBOR.KeyValue("keccak256.json", jsonKeccak256);

        bytes memory jsonDir = DAG_CBOR.mapCbor(jsonDirEntries);
        bytes memory actualJsonDirCID = DAG_CBOR.dagcbor(jsonDir);

        assertEq(actualJsonDirCID, DAGCBOR_TestData.JsonDirCID, "JSON directory CID mismatch");
    }

    function test_NestedDirectory() public pure {
        DAG_CBOR.KeyValue[] memory nestedDirEntries = new DAG_CBOR.KeyValue[](2);
        nestedDirEntries[0] = DAG_CBOR.KeyValue("raw", DAGCBOR_TestData.RawDirCID);
        nestedDirEntries[1] = DAG_CBOR.KeyValue("json", DAGCBOR_TestData.JsonDirCID);
        bytes memory nestedDir = DAG_CBOR.mapCbor(nestedDirEntries);
        bytes memory actualNestedDirCID = _wrapDagCborCID(nestedDir);
        assertEq(actualNestedDirCID, DAGCBOR_TestData.NestedDirCID, "Nested directory CID mismatch");
    }

    function test_RootDirectory() public pure {
        bytes memory rawFile = Raw.encode(bytes(DAGCBOR_TestData.HelloWorld));
        bytes memory jsonRaw = JSON_UTF8.encode(bytes('{"Hello":"World"}'));
        string memory indexHtml = "<h1>Hello World</h1>";
        bytes memory indexHtmlRaw = Raw.encode(bytes(indexHtml));
        DAG_CBOR.KeyValue[] memory rootDirEntries = new DAG_CBOR.KeyValue[](6);
        rootDirEntries[0] = DAG_CBOR.KeyValue(
            "raw", // raw dir
            DAGCBOR_TestData.RawDirCID
        );
        rootDirEntries[1] = DAG_CBOR.KeyValue(
            "json", // json dir
            DAGCBOR_TestData.JsonDirCID
        );
        rootDirEntries[2] = DAG_CBOR.KeyValue(
            "nested", // nested dir
            DAGCBOR_TestData.NestedDirCID
        );
        rootDirEntries[3] = DAG_CBOR.KeyValue("index.html", indexHtmlRaw);
        rootDirEntries[4] = DAG_CBOR.KeyValue("readme.txt", rawFile);
        rootDirEntries[5] = DAG_CBOR.KeyValue("config.json", jsonRaw);
        bytes memory rootDir = DAG_CBOR.mapCbor(rootDirEntries);
        bytes memory actualDirectoryCID = _wrapDagCborCID(rootDir);
        assertEq(actualDirectoryCID, DAGCBOR_TestData.DirectoryCID, "Root directory CID mismatch");
    }

    // ========== NEW TESTS FOR MISSING COVERAGE ==========

    function test_DagCborSha256() public pure {
        bytes memory data = bytes("Hello World");
        bytes memory result = DAG_CBOR.dagcborSha256(data);

        // Expected: 0x01711220 + SHA256 hash
        assertEq(result.length, 36, "DAG-CBOR SHA256 should be 36 bytes");
        assertEq(uint256(uint8(result[0])), 0x01, "First byte should be 0x01");
        assertEq(uint256(uint8(result[1])), 0x71, "Second byte should be 0x71");
        assertEq(uint256(uint8(result[2])), 0x12, "Third byte should be 0x12");
        assertEq(uint256(uint8(result[3])), 0x20, "Fourth byte should be 0x20");

        bytes32 expectedHash = sha256(data);
        bytes32 actualHash;
        assembly {
            actualHash := mload(add(result, 36))
        }
        assertEq(actualHash, expectedHash, "Hash should match SHA256");
    }

    function test_DagCborKeccak256() public pure {
        bytes memory data = bytes("Hello World");
        bytes memory result = DAG_CBOR.dagcborKeccak256(data);

        // Expected: 0x01711b20 + Keccak256 hash
        assertEq(result.length, 36, "DAG-CBOR Keccak256 should be 36 bytes");
        assertEq(uint256(uint8(result[0])), 0x01, "First byte should be 0x01");
        assertEq(uint256(uint8(result[1])), 0x71, "Second byte should be 0x71");
        assertEq(uint256(uint8(result[2])), 0x1b, "Third byte should be 0x1b");
        assertEq(uint256(uint8(result[3])), 0x20, "Fourth byte should be 0x20");

        bytes32 expectedHash = keccak256(data);
        bytes32 actualHash;
        assembly {
            actualHash := mload(add(result, 36))
        }
        assertEq(actualHash, expectedHash, "Hash should match Keccak256");
    }

    function test_EncodeLength() public pure {
        // Test all branches of encodeLength
        bytes memory result;

        // Branch 1: length < 24
        result = DAG_CBOR.encodeLength(5, DAG_CBOR.CBOR_TYPE_TEXT_STRING);
        assertEq(result.length, 1, "Length < 24 should be 1 byte");
        assertEq(uint256(uint8(result[0])), 0x65, "Should be 0x60 + 5");

        // Branch 2: length < 256
        result = DAG_CBOR.encodeLength(100, DAG_CBOR.CBOR_TYPE_TEXT_STRING);
        assertEq(result.length, 2, "Length < 256 should be 2 bytes");
        assertEq(uint256(uint8(result[0])), 0x78, "Should be 0x60 + 24");
        assertEq(uint256(uint8(result[1])), 100, "Should be the length");

        // Branch 3: length < 65536
        result = DAG_CBOR.encodeLength(1000, DAG_CBOR.CBOR_TYPE_TEXT_STRING);
        assertEq(result.length, 3, "Length < 65536 should be 3 bytes");
        assertEq(uint256(uint8(result[0])), 0x79, "Should be 0x60 + 25");
        assertEq(uint256(uint8(result[1])), 0x03, "Should be high byte of 1000");
        assertEq(uint256(uint8(result[2])), 0xe8, "Should be low byte of 1000");

        // Branch 4: length >= 65536
        result = DAG_CBOR.encodeLength(100000, DAG_CBOR.CBOR_TYPE_TEXT_STRING);
        assertEq(result.length, 5, "Length >= 65536 should be 5 bytes");
        assertEq(uint256(uint8(result[0])), 0x7a, "Should be 0x60 + 26");
    }

    function test_EncodeCID() public pure {
        bytes memory data = hex"1234567890abcdef";
        bytes memory result = DAG_CBOR.encodeCID(data);

        // Expected: DAG_CBOR_LINK_TAG (0xd82a) + length + 0x00 + data
        assertEq(uint256(uint8(result[0])), 0xd8, "First byte should be 0xd8");
        assertEq(uint256(uint8(result[1])), 0x2a, "Second byte should be 0x2a");
        // The length should be 0x40 + data.length + 1 (for the 0x00 prefix)
        assertEq(uint256(uint8(result[2])), 0x49, "Should be 0x40 + length (9)");
        assertEq(uint256(uint8(result[3])), 0x00, "Should be identity prefix");
        assertEq(result[4], data[0], "Should contain original data");
    }

    function test_ArrayCbor() public pure {
        bytes[] memory cids = new bytes[](2);
        cids[0] = hex"1234567890abcdef";
        cids[1] = hex"fedcba0987654321";

        bytes memory result = DAG_CBOR.arrayCbor(cids);

        // Should start with array length encoding
        assertEq(uint256(uint8(result[0])), 0x82, "Should be array with 2 elements");

        // Should contain two CIDs with proper encoding
        assertEq(uint256(uint8(result[1])), 0xd8, "First CID should start with 0xd8");
        assertEq(uint256(uint8(result[2])), 0x2a, "First CID should have 0x2a");
    }

    function test_NodeCbor() public {
        bytes memory data = bytes("Hello World");
        bytes[] memory links = new bytes[](1);
        links[0] = hex"1234567890abcdef";

        // Test complete node (both data and links)
        bytes memory result = DAG_CBOR.nodeCbor(data, links);
        assertTrue(result.length > 0, "Complete node should have data");

        // Test file node (only data, no links)
        result = DAG_CBOR.nodeCbor(data, new bytes[](0));
        assertEq(result, data, "File node should return data as-is");

        // Test directory node (only links, no data)
        result = DAG_CBOR.nodeCbor("", links);
        assertTrue(result.length > 0, "Directory node should have data");

        // Test empty node (should revert) - use helper contract
        NodeCborCaller helper = new NodeCborCaller();
        vm.expectRevert(abi.encodeWithSelector(DAG_CBOR.InvalidDAGCBOR.selector, "Empty node"));
        helper.callNodeCbor("", new bytes[](0));
    }

    function test_NodeCborEdgeCases() public pure {
        bytes memory data = bytes("Test data");
        bytes[] memory links = new bytes[](1);
        links[0] = hex"1234567890abcdef";

        // Test with empty data but valid links
        bytes memory result = DAG_CBOR.nodeCbor("", links);
        assertTrue(result.length > 0, "Directory node should be created");

        // Test with valid data but empty links
        result = DAG_CBOR.nodeCbor(data, new bytes[](0));
        assertEq(result, data, "File node should return data unchanged");
    }
}

contract NodeCborCaller {
    function callNodeCbor(bytes memory data, bytes[] memory links) external pure returns (bytes memory) {
        return DAG_CBOR.nodeCbor(data, links);
    }
}
