// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import {Test} from "forge-std/Test.sol";
import {IReentrance, ReentrancySolver} from "../src/solvers/10_ReentrancySolver.sol";

/// @title Ethernaut 10 - Re-entrancy Solution Test
/// @notice Verifies the callback sequence against the Solidity 0.6 target.
contract ReentrancyTest is Test {
    /// @notice Interface for the separately compiled Solidity 0.6 target.
    IReentrance target;

    /// @notice Contract used to complete the level.
    ReentrancySolver solver;

    /// @notice Account used to call the solver.
    address player = makeAddr("player");

    /// @notice Account that provides the target's starting balance.
    address depositor = makeAddr("depositor");

    /// @notice Deploys the legacy artifact and prepares the local accounts.
    function setUp() public {
        target = IReentrance(deployCode("10_Reentrancy.sol:Reentrance"));
        solver = new ReentrancySolver(address(target));

        vm.deal(player, 1 ether);
        vm.deal(depositor, 1 ether);
    }

    /// @notice Completes the level and verifies the final balances.
    function testSolve() public {
        vm.prank(depositor);
        target.donate{value: 0.5 ether}(depositor);

        assertEq(target.balanceOf(depositor), 0.5 ether);
        assertEq(address(target).balance, 0.5 ether);

        vm.prank(player);
        solver.solve{value: 1 ether}();

        assertEq(address(target).balance, 0);
        assertEq(address(solver).balance, 1.5 ether);
    }
}
