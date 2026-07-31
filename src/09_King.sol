// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

/// @title Ethernaut 09 - King
/// @notice Tracks the account that most recently paid at least the current prize.
/// @dev The original Ethernaut level behavior is preserved for local study.
contract King {
    /// @dev Address currently holding the king position.
    address king;

    /// @notice Minimum value required to replace the current king.
    uint256 public prize;

    /// @notice Account that deployed the level instance.
    address public owner;

    /// @notice Initializes the owner, king, and first prize from deployment value.
    constructor() payable {
        owner = msg.sender;
        king = msg.sender;
        prize = msg.value;
    }

    /// @notice Replaces the king after paying the previous king.
    receive() external payable {
        require(msg.value >= prize || msg.sender == owner);
        payable(king).transfer(msg.value);
        king = msg.sender;
        prize = msg.value;
    }

    /// @notice Returns the current king address.
    function _king() public view returns (address) {
        return king;
    }
}
