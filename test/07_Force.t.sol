// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import {Test} from "forge-std/Test.sol";
import {Force} from "../src/07_Force.sol";
import {ForceSolver} from "../src/solvers/07_ForceSolver.sol";

/// @title Ethernaut 07 - Force Solution Test
/// @notice Verifies that selfdestruct can transfer ETH to a contract without payable entry points.
contract ForceTest is Test {
    /// @notice Empty target that must receive ETH.
    Force target;

    /// @notice Helper contract that accepts and forwards ETH through selfdestruct.
    ForceSolver solver;

    /// @notice Account used to fund and trigger the solver.
    address player = makeAddr("player");

    /// @notice Deploys a fresh target and solver and funds the player.
    function setUp() public {
        target = new Force();
        solver = new ForceSolver();
        vm.deal(player, 1 ether);
    }

    /// @notice Funds the solver, destroys it, and confirms the forced target balance.
    function testSolve() public {
        assertEq(address(target).balance, 0);

        vm.startPrank(player);
        (bool funded,) = payable(solver).call{value: 0.1 ether}("");
        assertTrue(funded);

        solver.solve(payable(address(target)));
        vm.stopPrank();

        assertEq(address(target).balance, 0.1 ether);
    }
}
