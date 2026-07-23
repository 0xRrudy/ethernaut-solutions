// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import {CoinFlipSolver} from "../../src/solvers/03_CoinFlipSolver.sol";
import {LocalAnvilScript} from "../LocalAnvil.s.sol";

/// @title Local Coin Flip Solve Step
/// @notice Submits one prediction transaction to a previously deployed local solver.
contract SolveCoinFlip is LocalAnvilScript {
    function run() external {
        uint256 privateKey = localAnvilPrivateKey();
        address solverAddress = vm.envAddress("COINFLIP_SOLVER");

        vm.startBroadcast(privateKey);
        CoinFlipSolver(solverAddress).solve();
        vm.stopBroadcast();
    }
}
