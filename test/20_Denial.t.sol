// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import {Test} from "forge-std/Test.sol";
import {Denial} from "../src/20_Denial.sol";
import {DenialSolver} from "../src/solvers/20_DenialSolver.sol";

contract DenialTest is Test {
    Denial target;
    DenialSolver solver;
    address player = makeAddr("player");

    function setUp() public {
        target = new Denial();
        solver = new DenialSolver();
        target.setWithdrawPartner(address(solver));
        vm.deal(address(target), 1 ether);
    }

    function testSolve() public {
        address owner = target.owner();
        uint256 ownerBalanceBefore = owner.balance;

        assertEq(target.partner(), address(solver));
        assertEq(target.contractBalance(), 1 ether);

        vm.prank(player);
        (bool success,) = address(target).call{gas: 1_000_000}(abi.encodeWithSelector(Denial.withdraw.selector));

        assertFalse(success);
        assertEq(target.contractBalance(), 1 ether);
        assertEq(owner.balance, ownerBalanceBefore);
    }
}
