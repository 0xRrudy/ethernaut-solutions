// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import {console2} from "forge-std/console2.sol";
import {CoinFlip} from "../../src/03_CoinFlip.sol";
import {CoinFlipSolver} from "../../src/solvers/03_CoinFlipSolver.sol";
import {LocalAnvilScript} from "../LocalAnvil.s.sol";

/// @title Local Coin Flip Deployment
/// @notice Deploys the CoinFlip level and its solver to a local Anvil node.
contract DeployCoinFlip is LocalAnvilScript {
    string internal constant DEPLOYMENT_FILE = ".anvil/coinflip.env";

    function run() external returns (CoinFlip target, CoinFlipSolver solver) {
        uint256 privateKey = localAnvilPrivateKey();

        vm.startBroadcast(privateKey);
        target = new CoinFlip();
        solver = new CoinFlipSolver(address(target));
        vm.stopBroadcast();

        vm.writeFile(
            DEPLOYMENT_FILE,
            string.concat(
                "COINFLIP_TARGET=",
                vm.toString(address(target)),
                "\nCOINFLIP_SOLVER=",
                vm.toString(address(solver)),
                "\n"
            )
        );

        console2.log("CoinFlip target:", address(target));
        console2.log("CoinFlip solver:", address(solver));
        console2.log("Local deployment file:", DEPLOYMENT_FILE);
    }
}
