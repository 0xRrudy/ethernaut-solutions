// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import {Test} from "forge-std/Test.sol";
import {King} from "../src/09_King.sol";
import {KingSolver} from "../src/solvers/09_KingSolver.sol";

/// @title Ethernaut 09 - King Solution Test
/// @notice Verifies that a contract without a payable callback keeps the king position.
contract KingTest is Test {
    /// @notice King level instance under test.
    King target;

    /// @notice Contract used to claim and retain the king position.
    KingSolver solver;

    /// @notice Account used to call the solver.
    address player = makeAddr("player");

    /// @notice Account that deploys the target and may try to reclaim the position.
    address owner = makeAddr("owner");

    /// @notice Deploys a funded King instance and prepares the player.
    function setUp() public {
        vm.deal(owner, 10 ether);

        vm.prank(owner);
        target = new King{value: 0.1 ether}();

        solver = new KingSolver();
        vm.deal(player, 10 ether);
    }

    /// @notice Claims the position through the solver and confirms a later replacement fails.
    function testSolve() public {
        vm.prank(player);
        solver.solve{value: 1 ether}(payable(address(target)));

        assertEq(target._king(), address(solver));
        assertEq(target.prize(), 1 ether);

        vm.prank(owner);
        (bool reclaimed,) = address(target).call{value: 2 ether}("");

        assertFalse(reclaimed);
        assertEq(target._king(), address(solver));
        assertEq(target.prize(), 1 ether);
    }
}
