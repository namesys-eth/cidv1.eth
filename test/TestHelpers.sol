// SPDX-License-Identifier: WTFPL.ETH
pragma solidity ^0.8.25;

/**
 * @title TestHelpers
 * @author cidv1.eth
 * @notice Helper functions for testing multiformat implementations
 * @dev This library contains utility functions used across multiple test files
 * 
 * @custom:security-contact security@cidv1.eth
 * @custom:website https://cidv1.eth
 * @custom:license WTFPL.ETH
 */
library TestHelpers {
    /**
     * @notice Decodes a varint from bytes into a uint256 (for testing only)
     * @param data The bytes containing the varint to decode
     * @param offset The offset in data to start decoding from
     * @return value The decoded uint256 value
     * @return newOffset The new offset after decoding (offset + varint length)
     * @dev Reads bytes starting from offset until a byte with MSB=0 is found
     * @dev Each byte contributes 7 bits to the final value
     * @dev Reverts with "Invalid varint" if the varint is malformed or truncated
     * @dev Supports decoding varints of any length (not limited to 4 bytes)
     */
    function decodeVarint(bytes memory data, uint256 offset) internal pure returns (uint256 value, uint256 newOffset) {
        uint256 result = 0;
        uint256 shift = 0;
        uint256 i = offset;

        while (i < data.length) {
            uint8 byteValue = uint8(data[i]);
            result |= uint256(byteValue & 0x7f) << shift;
            if ((byteValue & 0x80) == 0) {
                return (result, i + 1);
            }
            shift += 7;
            i++;
        }

        revert("Invalid varint");
    }
} 