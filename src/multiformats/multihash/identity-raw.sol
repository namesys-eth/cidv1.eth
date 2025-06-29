// SPDX-License-Identifier: WTFPL.ETH
pragma solidity ^0.8.25;

import {Varint} from "../varint.sol";

/**
 * @title Identity
 * @author cidv1.eth
 * @notice Identity multihash encoding for multiformats
 * @dev This library implements Identity multihash encoding as defined in
 * the multihash specification. It provides a standardized way to encode
 * raw data with an identity hash function (no hashing, just raw data).
 *
 * Multihash format:
 * - First byte: hash function code (0x00 for Identity)
 * - Varint: data length
 * - Remaining bytes: the raw data (no hashing applied)
 *
 * Identity multihash is useful when you want to store raw data with
 * a multihash-compatible format, or when the data is already a hash
 * and you want to preserve it exactly.
 *
 * @custom:security-contact security@cidv1.eth
 * @custom:website https://cidv1.eth
 * @custom:license WTFPL.ETH
 */
library Identity {
    using Varint for uint256;

    /**
     * @notice Encodes data with Identity multihash (no hashing)
     * @param data The data to encode (not hashed, stored as-is)
     * @return result The Identity multihash encoded data
     * @dev Uses the standard Identity multihash prefix (0x00)
     * @dev Includes varint-encoded length followed by raw data
     * @dev Useful for storing raw data in multihash format
     */
    function encode(bytes memory data) internal pure returns (bytes memory result) {
        result = abi.encodePacked(hex"00", (data.length).varint(), data);
    }
}
