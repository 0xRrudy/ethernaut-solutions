// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import {Test} from "forge-std/Test.sol";
import {ElevatorSolver} from "../src/solvers/11_ElevatorSolver.sol";
import {Elevator} from "../src/11_Elevator.sol";

contract ElevatorTest is Test {
    Elevator target;
    ElevatorSolver solver;
    address player = makeAddr("player");

    function setUp() public {
        target = new Elevator();
        solver = new ElevatorSolver();
    }

    function testSolve() public {
        assertFalse(target.top());
        assertEq(target.floor(), 0);

        vm.prank(player);
        solver.solve(address(target));

        assertTrue(target.top());
        assertEq(target.floor(), 10);
    }
}
