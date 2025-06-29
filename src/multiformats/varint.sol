// SPDX-License-Identifier: WTFPL.ETH
pragma solidity ^0.8.25;

/**
 * @title Varint
 * @author cidv1.eth
 * @notice Variable-length integer encoding and decoding for multiformats
 * @dev This library implements the varint encoding scheme used in multiformats,
 * Protocol Buffers, and other binary serialization formats.
 * 
 * Varint encoding uses the most significant bit (MSB) as a continuation bit:
 * - If MSB is 0, the byte is the last byte of the varint
 * - If MSB is 1, more bytes follow
 * - The remaining 7 bits of each byte contain the actual data
 * 
 * This implementation supports up to 4-byte varints (28 bits), which is
 * sufficient for most multiformat use cases.
 */
library Varint {
    /**
     * @notice Error thrown when input number is too large for varint encoding
     * @param input The input number that exceeded the maximum value
     */
    error InputTooLarge(uint256 input);

    /**
     * @notice Encodes a number into varint format
     * @param _num Number to encode (must be < 268435456)
     * @return _varint Varint encoded number as bytes
     * @dev Uses continuation bit (0x80) for multi-byte encoding
     * @dev Supports 1-4 byte encoding depending on input size:
     *      - 1 byte: 0-127
     *      - 2 bytes: 128-16383
     *      - 3 bytes: 16384-2097151
     *      - 4 bytes: 2097152-268435455
     * @dev Reverts if input >= 268435456 (InputTooLarge error)
     */
    function varint(uint256 _num) internal pure returns (bytes memory _varint) {
        if (_num < 128) {
            return abi.encodePacked(uint8(_num));
        }
        if (_num < 16384) {
            // 128 * 128
            return abi.encodePacked(uint8((_num & 0x7F) | 0x80), uint8(_num >> 7));
        }
        if (_num < 2097152) {
            // 128 * 128 * 128
            return abi.encodePacked(uint8((_num & 0x7F) | 0x80), uint8((_num >> 7) & 0x7F) | 0x80, uint8(_num >> 14));
        }
        if (_num < 268435456) {
            // 128 * 128 * 128 * 128
            return abi.encodePacked(
                uint8((_num & 0x7F) | 0x80),
                uint8((_num >> 7) & 0x7F) | 0x80,
                uint8((_num >> 14) & 0x7F) | 0x80,
                uint8(_num >> 21)
            );
        }
        revert InputTooLarge(_num);
    }
}
