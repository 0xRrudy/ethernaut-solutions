// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

/// @title Ethernaut 04 - Telephone
/// @notice Allows ownership to change when the immediate caller differs from the transaction origin.
/// @dev The original Ethernaut level logic is preserved for security study.
contract Telephone {
    /// @notice Address currently recorded as the owner.
    address public owner;

    /// @notice Assigns the deployer as the initial owner.
    constructor() {
        owner = msg.sender;
    }

    /// @notice Changes the owner when called through an intermediary contract.
    /// @dev Using tx.origin for authorization makes the result depend on the entire call chain.
    /// @param _owner Address to assign as the new owner.
    function changeOwner(address _owner) public {
        if (tx.origin != msg.sender) {
            owner = _owner;
        }
    }
}
