// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import {Test} from "forge-std/Test.sol";
import {Privacy} from "../src/12_Privacy.sol";

contract PrivacyTest is Test {
    Privacy target;
    address player = makeAddr("player");

    function setUp() public {
        bytes32[3] memory initialData;
        initialData[0] = keccak256(abi.encodePacked("dummy_data_0"));
        initialData[1] = keccak256(abi.encodePacked("dummy_data_1"));
        initialData[2] = keccak256(abi.encodePacked("dummy_data_2"));
        target = new Privacy(initialData);
    }

    function testSolve() public {
        bytes16 key = bytes16(vm.load(address(target), bytes32(uint256(5))));

        vm.prank(player);
        target.unlock(key);
        assertEq(target.locked(), false);
    }
}
