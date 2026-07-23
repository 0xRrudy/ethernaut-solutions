// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

/// @title Ethernaut 03 - Coin Flip
/// @notice Records consecutive wins when callers correctly guess a deterministic coin flip.
/// @dev The intentionally vulnerable Ethernaut logic is preserved for security study.
contract CoinFlip {
    /// @notice Number of correct guesses made without an incorrect guess in between.
    uint256 public consecutiveWins;

    /// @dev Previous block-hash value used to prevent more than one guess per block.
    uint256 lastHash;

    /// @dev Dividing a 256-bit block hash by 2^255 reduces the result to either 0 or 1.
    uint256 FACTOR = 57896044618658097711785492504343953926634992332820282019728792003956564819968;

    /// @notice Initializes the consecutive-win counter.
    constructor() {
        consecutiveWins = 0;
    }

    /// @notice Compares a caller's guess with a value derived from the previous block hash.
    /// @dev The previous block hash is public and can be calculated by another contract in the same transaction.
    /// @param _guess The predicted coin-flip result.
    /// @return Whether the submitted guess matched the calculated result.
    function flip(bool _guess) public returns (bool) {
        uint256 blockValue = uint256(blockhash(block.number - 1));

        if (lastHash == blockValue) {
            revert();
        }

        lastHash = blockValue;
        uint256 coinFlip = blockValue / FACTOR;
        bool side = coinFlip == 1 ? true : false;

        if (side == _guess) {
            consecutiveWins++;
            return true;
        } else {
            consecutiveWins = 0;
            return false;
        }
    }
}
