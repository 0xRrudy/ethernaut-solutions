// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

/// @title Ethernaut 08 - Vault
/// @notice Locks until a caller supplies the bytes32 value stored as its password.
/// @dev private restricts Solidity access but does not make on-chain storage confidential.
contract Vault {
    /// @notice Whether the vault remains locked.
    bool public locked;

    /// @dev Password stored in storage slot 1 after the Boolean in slot 0.
    bytes32 private password;

    /// @notice Creates a locked vault with a supplied password.
    /// @param _password Value required to unlock the vault.
    constructor(bytes32 _password) {
        locked = true;
        password = _password;
    }

    /// @notice Unlocks the vault when the supplied value matches storage.
    /// @param _password Candidate password read by the caller.
    function unlock(bytes32 _password) public {
        if (password == _password) {
            locked = false;
        }
    }
}
