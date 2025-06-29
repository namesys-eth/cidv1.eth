// SPDX-License-Identifier: WTFPL.ETH
pragma solidity ^0.8.25;

import "forge-std/Test.sol";
import {SHA256} from "../src/multiformats/multihash/sha-256.sol";

contract SHA256Test is Test {
    function test_EncodeEmpty() public pure {
        bytes memory result = SHA256.encode("");
        assertEq(result.length, 34, "SHA256 multihash should be 34 bytes");
        assertEq(uint256(uint8(result[0])), 0x12, "First byte should be 0x12 (SHA256 code)");
        assertEq(uint256(uint8(result[1])), 0x20, "Second byte should be 0x20 (32 length)");
        bytes32 expected = sha256("");
        bytes32 actual;
        assembly { actual := mload(add(result, 34)) }
        assertEq(actual, expected, "Hash should match SHA256 of empty");
    }
    function test_EncodeShort() public pure {
        bytes memory data = bytes("hello");
        bytes memory result = SHA256.encode(data);
        assertEq(result.length, 34);
        assertEq(uint256(uint8(result[0])), 0x12);
        assertEq(uint256(uint8(result[1])), 0x20);
        bytes32 expected = sha256(data);
        bytes32 actual;
        assembly { actual := mload(add(result, 34)) }
        assertEq(actual, expected);
    }
    function test_EncodeLong() public pure {
        bytes memory data = new bytes(100);
        for (uint i = 0; i < 100; i++) data[i] = bytes1(uint8(i));
        bytes memory result = SHA256.encode(data);
        assertEq(result.length, 34);
        assertEq(uint256(uint8(result[0])), 0x12);
        assertEq(uint256(uint8(result[1])), 0x20);
        bytes32 expected = sha256(data);
        bytes32 actual;
        assembly { actual := mload(add(result, 34)) }
        assertEq(actual, expected);
    }

    function test_InternalSha256() public pure {
        bytes memory data = bytes("Hello World");
        bytes memory result = SHA256._sha256(data);
        
        // Should be same as encode
        bytes memory expected = SHA256.encode(data);
        assertEq(result, expected, "_sha256 should equal encode");
    }
} 