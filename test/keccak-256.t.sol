// SPDX-License-Identifier: WTFPL.ETH
pragma solidity ^0.8.25;

import "forge-std/Test.sol";
import {KECCAK256} from "../src/multiformats/multihash/keccak-256.sol";

contract KECCAK256Test is Test {
    function test_EncodeEmpty() public pure {
        bytes memory result = KECCAK256.encode("");
        assertEq(result.length, 34, "KECCAK256 multihash should be 34 bytes");
        assertEq(uint256(uint8(result[0])), 0x1b, "First byte should be 0x1b (KECCAK256 code)");
        assertEq(uint256(uint8(result[1])), 0x20, "Second byte should be 0x20 (32 length)");
        bytes32 expected = keccak256("");
        bytes32 actual;
        assembly {
            actual := mload(add(result, 34))
        }
        assertEq(actual, expected, "Hash should match keccak256 of empty");
    }

    function test_EncodeShort() public pure {
        bytes memory data = bytes("hello");
        bytes memory result = KECCAK256.encode(data);
        assertEq(result.length, 34);
        assertEq(uint256(uint8(result[0])), 0x1b);
        assertEq(uint256(uint8(result[1])), 0x20);
        bytes32 expected = keccak256(data);
        bytes32 actual;
        assembly {
            actual := mload(add(result, 34))
        }
        assertEq(actual, expected);
    }

    function test_EncodeLong() public pure {
        bytes memory data = new bytes(100);
        for (uint256 i = 0; i < 100; i++) {
            data[i] = bytes1(uint8(i));
        }
        bytes memory result = KECCAK256.encode(data);
        assertEq(result.length, 34);
        assertEq(uint256(uint8(result[0])), 0x1b);
        assertEq(uint256(uint8(result[1])), 0x20);
        bytes32 expected = keccak256(data);
        bytes32 actual;
        assembly {
            actual := mload(add(result, 34))
        }
        assertEq(actual, expected);
    }

    function test_InternalKeccak256() public pure {
        bytes memory data = bytes("Hello World");
        bytes memory result = KECCAK256._keccak256(data);

        // Should be same as encode
        bytes memory expected = KECCAK256.encode(data);
        assertEq(result, expected, "_keccak256 should equal encode");
    }
}
