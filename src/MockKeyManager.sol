/// @title MockKeyVerifier
/// @notice A mock contract for testing that always returns true for batch signature verification.
contract MockKeyVerifier {
    /// @notice Verifies batch signatures over a data hash, always returning true for testing purposes.
    /// @param dataHash Keccak hash over the batch data.
    /// @param signatures Signatures over the batch data's keccak hash.
    /// @return Always returns true.
    function verifyBatchSignatures(bytes32 dataHash, bytes memory signatures) public view returns (bool) {
        return true;
    }
}