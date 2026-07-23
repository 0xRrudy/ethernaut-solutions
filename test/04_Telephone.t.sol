// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import {Test} from "forge-std/Test.sol";
import {Telephone} from "../src/04_Telephone.sol";
import {TelephoneSolver} from "../src/solvers/04_TelephoneSolver.sol";

/// @title Ethernaut 04 - Telephone Solution Test
/// @notice Verifies the difference between a direct call and a call through an intermediary contract.
contract TelephoneTest is Test {
    /// @notice Telephone level instance under test.
    Telephone target;

    /// @notice Intermediary contract used to solve the level.
    TelephoneSolver solver;

    /// @notice Account used to solve the level.
    address player = makeAddr("player");

    /// @notice Deploys a fresh target and solver before each test.
    function setUp() public {
        target = new Telephone();
        solver = new TelephoneSolver(address(target));
    }

    /// @notice Confirms that a direct call keeps tx.origin equal to msg.sender.
    function testDirectCallDoesNotChangeOwner() public {
        address initialOwner = target.owner();

        vm.prank(player, player);
        target.changeOwner(player);

        assertEq(target.owner(), initialOwner);
    }

    /// @notice Changes ownership by calling the target through the solver.
    function testSolve() public {
        assertEq(target.owner(), address(this));

        // The player starts the transaction, so both values are player at the first call.
        vm.prank(player, player);
        solver.solve(player);

        // Inside Telephone, tx.origin is player while msg.sender is the solver.
        assertEq(target.owner(), player);
    }
}
