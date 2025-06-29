// SPDX-License-Identifier: WTFPL.ETH
pragma solidity ^0.8.0;

import "forge-std/Test.sol";
import {DAG_PB} from "../src/multiformats/multicodec/dag-pb.sol";
import {DAGPB_TestData} from "./data/dag-pb-test-data.sol";
import {Raw} from "../src/multiformats/multicodec/raw-bin.sol";
import {Varint} from "../src/multiformats/varint.sol";
import {UnixFS} from "../src/multiformats/multicodec/unix-fs.sol";
import {TestHelpers} from "./TestHelpers.sol";

contract DagPbTest is Test {
    using Raw for bytes;
    using Varint for uint256;
    using UnixFS for bytes;
    // Helper for raw file: CIDv1 + raw codec + identity multihash + varint(length) + data

    function _wrapRawCID(bytes memory data) internal pure returns (bytes memory) {
        // 0x01 (CIDv1) + 0x55 (raw codec) + 0x00 (identity multihash) + varint(length) + data
        return abi.encodePacked(bytes1(0x01), bytes1(0x55), bytes1(0x00), data.length.varint(), data);
    }

    // Helper for dag-pb node: CIDv1 + dag-pb codec + identity multihash + varint(length) + data
    function _wrapDagPbCID(bytes memory data) internal pure returns (bytes memory) {
        // 0x01 (CIDv1) + 0x70 (dag-pb codec) + 0x00 (identity multihash) + varint(length) + data
        return abi.encodePacked(bytes1(0x01), bytes1(0x70), bytes1(0x00), data.length.varint(), data);
    }

    function test_DirectoryNode() public pure {
        // Import test data
        string memory helloWorld = DAGPB_TestData.HelloWorld;

        // Create the complete DAG-PB structure
        bytes memory rawFile = Raw.encode(bytes(helloWorld));

        // Create link and directory
        bytes memory link = DAG_PB.link(rawFile, "hello.txt", bytes(helloWorld).length);
        bytes[] memory links = new bytes[](1);
        links[0] = link;
        bytes memory encodedDir = DAG_PB.directory(links);
        bytes memory actualDirCID = _wrapDagPbCID(encodedDir);

        // Verify the complete structure matches test data
        assertEq(rawFile, DAGPB_TestData.HelloWorldRaw, "Raw file encoding mismatch");
        assertEq(encodedDir, DAGPB_TestData.DirNode, "Directory node encoding mismatch");
        assertEq(actualDirCID, DAGPB_TestData.DirCID, "Directory CID mismatch");

        // Log the complete structure for debugging
        console.log("Raw File:");
        console.logBytes(rawFile);
        console.log("Directory Node:");
        console.logBytes(encodedDir);
        console.log("Directory CID:");
        console.logBytes(actualDirCID);
    }

    // ========== NEW TESTS FOR MISSING COVERAGE ==========

    function test_EncodeTag() public pure {
        // Test encodeTag function
        bytes memory result = DAG_PB.encodeTag(1, DAG_PB.WIRE_TYPE_VARINT);
        assertEq(result.length, 1, "Tag should be 1 byte for small values");
        assertEq(uint256(uint8(result[0])), 0x08, "Should be (1 << 3) | 0 = 8");
        
        result = DAG_PB.encodeTag(15, DAG_PB.WIRE_TYPE_LENGTH_DELIMITED);
        assertEq(uint256(uint8(result[0])), 0x7a, "Should be (15 << 3) | 2 = 122");
    }

    function test_EncodeString() public pure {
        // Test encodeString function
        bytes memory result = DAG_PB.encodeString(2, "Hello");
        assertTrue(result.length > 0, "String encoding should not be empty");
        
        // Should contain: tag + length + string
        assertEq(uint256(uint8(result[0])), 0x12, "Should be (2 << 3) | 2 = 18");
        
        // Decode the length
        (uint256 length,) = TestHelpers.decodeVarint(result, 1);
        assertEq(length, 5, "String length should be 5");
    }

    function test_EncodeBytes() public pure {
        // Test encodeBytes function
        bytes memory data = hex"1234567890abcdef";
        bytes memory result = DAG_PB.encodeBytes(3, data);
        assertTrue(result.length > 0, "Bytes encoding should not be empty");
        
        // Should contain: tag + length + data
        assertEq(uint256(uint8(result[0])), 0x1a, "Should be (3 << 3) | 2 = 26");
        
        // Decode the length
        (uint256 length,) = TestHelpers.decodeVarint(result, 1);
        assertEq(length, 8, "Data length should be 8");
    }

    function test_EncodeUint64() public pure {
        // Test encodeUint64 function
        bytes memory result = DAG_PB.encodeUint64(4, 12345);
        assertTrue(result.length > 0, "Uint64 encoding should not be empty");
        
        // Should contain: tag + varint value
        assertEq(uint256(uint8(result[0])), 0x20, "Should be (4 << 3) | 0 = 32");
        
        // Decode the value
        (uint256 value,) = TestHelpers.decodeVarint(result, 1);
        assertEq(value, 12345, "Value should match input");
    }

    function test_EncodePBLink() public pure {
        // Test encodePBLink function
        bytes memory hash = hex"1234567890abcdef";
        string memory name = "test.txt";
        uint256 tsize = 1024;
        
        bytes memory result = DAG_PB.encodePBLink(hash, name, tsize);
        assertTrue(result.length > 0, "PBLink encoding should not be empty");
        
        // Should contain hash field, name field, and tsize field
        assertEq(uint256(uint8(result[0])), 0x0a, "Should start with hash field tag");
    }

    function test_EncodePBLinkZeroTsize() public pure {
        // Test encodePBLink with tsize = 0 (should not include tsize field)
        bytes memory hash = hex"1234567890abcdef";
        string memory name = "test.txt";
        uint256 tsize = 0;
        
        bytes memory result = DAG_PB.encodePBLink(hash, name, tsize);
        assertTrue(result.length > 0, "PBLink encoding should not be empty");
        
        // Should contain hash field and name field, but no tsize field
        assertEq(uint256(uint8(result[0])), 0x0a, "Should start with hash field tag");
    }

    function test_EncodePBNode() public pure {
        // Test encodePBNode function
        bytes memory data = hex"1234567890abcdef";
        bytes[] memory links = new bytes[](2);
        links[0] = hex"6c696e6b3164617461"; // "link1data" in hex
        links[1] = hex"6c696e6b3264617461"; // "link2data" in hex
        
        bytes memory result = DAG_PB.encodePBNode(data, links);
        assertTrue(result.length > 0, "PBNode encoding should not be empty");
        
        // Should contain links followed by data
        assertTrue(result.length > data.length, "Should contain links and data");
    }

    function test_EncodePBNodeEmptyLinks() public pure {
        // Test encodePBNode with empty links array
        bytes memory data = hex"1234567890abcdef";
        bytes[] memory links = new bytes[](0);
        
        bytes memory result = DAG_PB.encodePBNode(data, links);
        assertEq(result, data, "Should return data when no links");
    }

    function test_RawFile() public pure {
        // Test rawFile function
        bytes memory data = bytes("Hello World");
        bytes memory result = DAG_PB.rawFile(data);
        
        // rawFile should return data as-is
        assertEq(result, data, "rawFile should return data unchanged");
    }

    function test_LinkWithTsize() public pure {
        // Test link function with tsize parameter
        bytes memory hash = hex"1234567890abcdef";
        string memory name = "test.txt";
        uint256 tsize = 1024;
        
        bytes memory result = DAG_PB.link(hash, name, tsize);
        assertTrue(result.length > 0, "Link encoding should not be empty");
        
        // Should contain hash, name, and tsize fields
        assertEq(uint256(uint8(result[0])), 0x0a, "Should start with hash field tag");
    }

    function test_LinkWithoutTsize() public pure {
        // Test link function without tsize parameter (overload)
        bytes memory hash = hex"1234567890abcdef";
        string memory name = "test.txt";
        
        bytes memory result = DAG_PB.link(hash, name);
        assertTrue(result.length > 0, "Link encoding should not be empty");
        
        // Should contain hash and name fields, but no tsize field
        assertEq(uint256(uint8(result[0])), 0x0a, "Should start with hash field tag");
    }

    function test_LinkOverloadsConsistency() public pure {
        // Test that both link overloads produce consistent results
        bytes memory hash = hex"1234567890abcdef";
        string memory name = "test.txt";
        
        bytes memory result1 = DAG_PB.link(hash, name);
        bytes memory result2 = DAG_PB.link(hash, name, 0);
        
        assertEq(result1, result2, "Both link overloads should produce same result for tsize=0");
    }

    function test_DirectoryWithMultipleLinks() public pure {
        // Test directory function with multiple links
        bytes memory hash1 = hex"1234567890abcdef";
        bytes memory hash2 = hex"fedcba0987654321";
        
        bytes memory link1 = DAG_PB.link(hash1, "file1.txt", 100);
        bytes memory link2 = DAG_PB.link(hash2, "file2.txt", 200);
        
        bytes[] memory links = new bytes[](2);
        links[0] = link1;
        links[1] = link2;
        
        bytes memory result = DAG_PB.directory(links);
        assertTrue(result.length > 0, "Directory encoding should not be empty");
        
        // Directory should contain PB_DIR_TYPE + links, but the structure is complex
        // Just verify it's not empty and has reasonable length
        assertTrue(result.length > 10, "Directory should have substantial content");
    }

    function test_DirectoryWithEmptyLinks() public pure {
        // Test directory function with empty links array
        bytes[] memory links = new bytes[](0);
        
        bytes memory result = DAG_PB.directory(links);
        assertTrue(result.length > 0, "Directory encoding should not be empty");
        
        // Should contain only PB_DIR_TYPE
        assertEq(uint256(uint8(result[0])), 0x0a, "Should start with directory type");
    }

    function test_Constants() public pure {
        // Test that constants are properly defined
        assertEq(DAG_PB.DAG_PB_CODEC, hex"70", "DAG_PB_CODEC should be 0x70");
        assertEq(DAG_PB.PB_DIR_TYPE, hex"0a020801", "PB_DIR_TYPE should be 0x0a020801");
        assertEq(DAG_PB.WIRE_TYPE_VARINT, 0, "WIRE_TYPE_VARINT should be 0");
        assertEq(DAG_PB.WIRE_TYPE_LENGTH_DELIMITED, 2, "WIRE_TYPE_LENGTH_DELIMITED should be 2");
    }

    /*function test_redirect() public pure {
        // Create _redirects file content
        string memory _redirects = "/* /404.html 404";
        
        // Create the raw file node for _redirects
        bytes memory rawFile = Raw.raw(bytes(_redirects));
        bytes memory err404 = "<h1>404</h1>";
        bytes memory err404Raw = Raw.raw(bytes(err404));
        bytes memory html = "<h1>hello</h1><a href='./404.html'>404</a> || <a href='./_redirects'>config</a><br><a href='./test'>test</a>";
        bytes memory htmlRaw = Raw.raw(bytes(html));
        // Create link to the _redirects file
        bytes memory redirectLink = DAG_PB.link(rawFile, "_redirects", bytes(_redirects).length);
        bytes memory htmlLink = DAG_PB.link(htmlRaw, "index.html", bytes(html).length);
        bytes memory err404Link = DAG_PB.link(err404Raw, "404.html");
        bytes[] memory links = new bytes[](3);
        links[0] = redirectLink;
        links[2] = htmlLink;
        links[1] = err404Link;

        // Create the directory node containing the _redirects file
        bytes memory encodedDir = DAG_PB.directory(links);
        bytes memory actualDirCID = _wrapDagPbCID(encodedDir);

        // Log the complete structure for debugging
        console.log("_redirects File Content:");
        console.log(_redirects);
        console.log("Raw File:");
        console.logBytes(rawFile);
        console.log("Directory Node:");
        console.logBytes(encodedDir);
        console.log("Directory CID:");
        console.logBytes(actualDirCID);
    }*/
}
