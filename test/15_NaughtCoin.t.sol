// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import {Test} from "forge-std/Test.sol";
import {NaughtCoin} from "../src/15_NaughtCoin.sol";

contract NaughtCoinTest is Test {
    NaughtCoin target;
    address player = makeAddr("player");
    address spender = makeAddr("spender");

    function setUp() public {
        target = new NaughtCoin(player);
    }

    function testSolve() public {
        uint256 amount = target.balanceOf(player);

        assertEq(amount, target.INITIAL_SUPPLY());

        vm.startPrank(player);
        vm.expectRevert();
        // forge-lint: disable-next-line(erc20-unchecked-transfer)
        target.transfer(spender, 1);
        assertTrue(target.approve(spender, amount));
        vm.stopPrank();

        vm.prank(spender);
        assertTrue(target.transferFrom(player, spender, amount));

        assertEq(target.balanceOf(player), 0);
        assertEq(target.balanceOf(spender), amount);
        assertEq(target.allowance(player, spender), 0);
    }
}
