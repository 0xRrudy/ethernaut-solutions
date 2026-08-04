// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import {Test} from "forge-std/Test.sol";
import {MagicNum} from "../src/18_MagicNumber.sol";

contract MagicNumberTest is Test {
    MagicNum target;

    function setUp() public {
        target = new MagicNum();
    }

    function testSolve() public {
        // The first 12 bytes return the final 10 bytes as deployed runtime code.
        bytes memory creationCode = hex"600a600c600039600a6000f3602a60805260206080f3";
        address solver;

        assembly {
            solver := create(0, add(creationCode, 0x20), mload(creationCode))
        }

        assertNotEq(solver, address(0));

        target.setSolver(solver);
        assertEq(target.solver(), solver);
        assertEq(solver.code.length, 10);

        (bool success, bytes memory returnData) = solver.staticcall(abi.encodeWithSignature("whatIsTheMeaningOfLife()"));

        assertTrue(success);
        assertEq(returnData.length, 32);
        assertEq(abi.decode(returnData, (uint256)), 42);
    }
}
