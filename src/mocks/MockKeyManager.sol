// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

/// @title MockKeyVerifier
/// @dev   Used only in tests
contract MockKeyManager {
    /// @notice Verifies batch signatures over a data hash, always returning true for testing purposes.
    /// @dev    Both parameters are intentionally unused.
    /// @return true
    function verifyQuorumSignatures(
        bytes32,
        /* dataHash */
        bytes memory /* signatures */
    )
        public
        pure
        returns (bool)
    {
        return true;
    }
}
