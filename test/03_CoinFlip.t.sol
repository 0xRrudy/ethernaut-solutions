// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import {Test} from "forge-std/Test.sol";
import {CoinFlip} from "../src/03_CoinFlip.sol";
import {CoinFlipSolver} from "../src/solvers/03_CoinFlipSolver.sol";

/// @title Ethernaut 03 - Coin Flip Solver Test
/// @notice Verifies that the previous block hash allows ten consecutive outcomes to be predicted.
contract CoinFlipTest is Test {
    /// @notice Vulnerable target contract.
    CoinFlip target;

    /// @notice Contract that predicts and submits each coin-flip result.
    CoinFlipSolver solver;

    /// @notice Account used to trigger the solver.
    address player = makeAddr("player");

    /// @notice Deploys a fresh target and solver contract before each test.
    function setUp() public {
        target = new CoinFlip();
        solver = new CoinFlipSolver(address(target));
        vm.deal(player, 1 ether);
    }

    /// @notice Predicts the target's result once per simulated block for ten rounds.
    function testSolve() public {
        vm.startPrank(player);

        for (uint256 round = 0; round < 10; ++round) {
            // Move forward because the target rejects a reused block hash.
            vm.roll(block.number + 1);

            // Forge unit tests do not mine historical blocks automatically, so provide
            // a distinct simulated hash for the previous block.
            uint256 previousBlockNumber = block.number - 1;
            bytes32 simulatedPreviousBlockHash = keccak256(abi.encodePacked(block.number, round));
            vm.setBlockhash(previousBlockNumber, simulatedPreviousBlockHash);

            // The solver and target read the same public previous block hash.
            solver.solve();

            assertEq(target.consecutiveWins(), round + 1);
        }

        vm.stopPrank();
    }
}
