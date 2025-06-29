// SPDX-License-Identifier: WTFPL.ETH
pragma solidity ^0.8.25;

import "forge-std/Test.sol";
import {Identity} from "../src/multiformats/multihash/identity-raw.sol";
import {TestHelpers} from "./TestHelpers.sol";

contract IdentityTest is Test {
    function test_EncodeEmpty() public pure {
        bytes memory result = Identity.encode("");
        assertEq(uint256(uint8(result[0])), 0x00, "First byte should be 0x00 (Identity code)");
        (uint256 len, uint256 offset) = TestHelpers.decodeVarint(result, 1);
        assertEq(len, 0, "Varint length should be 0");
        assertEq(result.length, offset, "No data after varint for empty");
    }

    function test_EncodeShort() public pure {
        bytes memory data = bytes("hi");
        bytes memory result = Identity.encode(data);
        assertEq(uint256(uint8(result[0])), 0x00);
        (uint256 len, uint256 offset) = TestHelpers.decodeVarint(result, 1);
        assertEq(len, 2);
        assertEq(result.length, offset + 2);
        assertEq(result[offset], data[0]);
        assertEq(result[offset + 1], data[1]);
    }

    function test_EncodeLong() public pure {
        bytes memory data = new bytes(200);
        for (uint256 i = 0; i < 200; i++) {
            data[i] = bytes1(uint8(i));
        }
        bytes memory result = Identity.encode(data);
        assertEq(uint256(uint8(result[0])), 0x00);
        (uint256 len, uint256 offset) = TestHelpers.decodeVarint(result, 1);
        assertEq(len, 200);
        for (uint256 i = 0; i < 200; i++) {
            assertEq(result[offset + i], data[i]);
        }
    }
}
