// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import {Test} from "forge-std/Test.sol";
import {GatekeeperTwo} from "../src/14_GatekeeperTwo.sol";
import {GatekeeperTwoSolver} from "../src/solvers/14_GatekeeperTwoSolver.sol";

contract GatekeeperTwoTest is Test {
    GatekeeperTwo target;
    GatekeeperTwoSolver solver;
    address player = makeAddr("player");

    function setUp() public {
        target = new GatekeeperTwo();
    }

    function testSolve() public {
        assertEq(target.entrant(), address(0));

        vm.prank(player, player);
        solver = new GatekeeperTwoSolver(address(target));

        assertEq(target.entrant(), player);
    }
}
