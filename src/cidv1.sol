// SPDX-License-Identifier: WTFPL.ETH
pragma solidity ^0.8.25;

/**
 * @title CIDv1
 * @author cidv1.eth
 * @notice Content Identifier (CID) version 1 implementation for IPFS/IPLD
 * @dev This contract provides basic CIDv1 encoding and decoding functionality
 * 
 * CIDv1 is a self-describing content-addressed identifier that includes:
 * - Version prefix (0x01)
 * - Multicodec identifier
 * - Multihash digest
 * 
 * @custom:security-contact security@cidv1.eth
 * @custom:website https://cidv1.eth
 * @custom:license WTFPL.ETH
 */
contract CIDv1 {
    /**
     * @notice Encodes data into CIDv1 format
     * @param data The data to encode
     * @return The CIDv1 encoded data with version prefix
     * @dev Currently implements basic version 1 prefix (0x01)
     * @dev Future versions will support full multiformat encoding
     */
    function encode(bytes memory data) public pure returns (bytes memory) {
        return abi.encodePacked(hex"01", data);
    }

    /**
     * @notice Decodes CIDv1 data back to original format
     * @param data The CIDv1 encoded data to decode
     * @return The decoded data without version prefix
     * @dev Removes the version prefix (0x01) from the beginning
     * @dev Future versions will support full multiformat decoding
     */
    function decode(bytes memory data) public pure returns (bytes memory) {
        require(data.length > 0, "Empty data");
        require(data[0] == 0x01, "Invalid CIDv1 version");
        
        bytes memory result = new bytes(data.length - 1);
        for (uint256 i = 1; i < data.length; i++) {
            result[i - 1] = data[i];
        }
        return result;
    }
}
