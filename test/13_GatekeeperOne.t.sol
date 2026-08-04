// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import {Test} from "forge-std/Test.sol";
import {GatekeeperOne} from "../src/13_GatekeeperOne.sol";
import {GatekeeperOneSolver} from "../src/solvers/13_GatekeeperOneSolver.sol";

contract GatekeeperOneTest is Test {
    GatekeeperOne target;
    GatekeeperOneSolver solver;
    address player = makeAddr("player");

    function setUp() public {
        target = new GatekeeperOne();
        solver = new GatekeeperOneSolver();
    }

    function testSolve() public {
        // Bits 16–31 stay zero, bits 32–63 are nonzero, and the low 16 bits
        // reproduce tx.origin as required by the three key constraints.
        // casting to 'uint16' is safe because the gate intentionally compares only the low 16 address bits
        // forge-lint: disable-next-line(unsafe-typecast)
        uint64 keyValue = (uint64(1) << 32) | uint16(uint160(player));
        bytes8 key = bytes8(keyValue);

        vm.prank(player, player);
        bool result = solver.solve(address(target), key);

        assertTrue(result);
        assertEq(target.entrant(), player);
    }
}
