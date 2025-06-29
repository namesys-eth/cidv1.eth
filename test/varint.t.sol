// SPDX-License-Identifier: WTFPL.ETH
pragma solidity ^0.8.25;

import "forge-std/Test.sol";
import {Varint} from "../src/multiformats/varint.sol";
import {TestHelpers} from "./TestHelpers.sol";

contract VarintTest is Test {
    function test_EncodeDecode() public pure {
        uint256[] memory values = new uint256[](10);
        values[0] = 0;
        values[1] = 1;
        values[2] = 127;
        values[3] = 128;
        values[4] = 255;
        values[5] = 16383;
        values[6] = 16384;
        values[7] = 2097151;
        values[8] = 2097152;
        values[9] = 268435455;
        for (uint256 i = 0; i < values.length; i++) {
            bytes memory enc = Varint.varint(values[i]);
            (uint256 dec, uint256 offset) = TestHelpers.decodeVarint(enc, 0);
            assertEq(dec, values[i], "Round-trip varint");
            assertEq(offset, enc.length, "Offset matches length");
        }
    }

    function test_TooLargeReverts() public {
        VarintCaller helper = new VarintCaller();
        vm.expectRevert(abi.encodeWithSelector(Varint.InputTooLarge.selector, 268435456));
        helper.callVarint(268435456);
    }
}

contract VarintCaller {
    function callVarint(uint256 value) external pure returns (bytes memory) {
        return Varint.varint(value);
    }
}
