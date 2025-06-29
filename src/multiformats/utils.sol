// SPDX-License-Identifier: WTFPL.ETH
pragma solidity ^0.8.25;

import {LibBytes} from "solady/utils/LibBytes.sol";

/**
 * @title Utils
 * @author cidv1.eth
 * @notice Utility functions for multiformat operations
 * @dev This library provides common utility functions that are shared across
 * multiple multiformat libraries. It uses Solady's LibBytes for efficient
 * byte manipulation operations.
 *
 * The library is designed to be minimal and focused, containing only functions
 * that are not already implemented in other multiformat libraries or Solady.
 *
 * @custom:security-contact security@cidv1.eth
 * @custom:website https://cidv1.eth
 * @custom:license WTFPL.ETH
 */
library Utils {
    using LibBytes for bytes;

    /**
     * @notice Reserved for future utility functions
     * @dev This library is intentionally minimal to avoid duplication with
     * other libraries. New utility functions should be added here only if
     * they are not available in Solady or other multiformat libraries.
     *
     * Potential future additions:
     * - Custom byte manipulation functions
     * - Multiformat-specific validation helpers
     * - Cross-library compatibility functions
     */
}
