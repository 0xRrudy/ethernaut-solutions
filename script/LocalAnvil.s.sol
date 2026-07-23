// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import {Script} from "forge-std/Script.sol";

/// @notice Shared safety checks for scripts that must run only against a local Anvil node.
abstract contract LocalAnvilScript is Script {
    uint256 internal constant LOCAL_ANVIL_CHAIN_ID = 31337;
    address internal constant LOCAL_ANVIL_ACCOUNT = 0xf39Fd6e51aad88F6F4ce6aB8827279cffFb92266;

    /// @notice Loads and validates Anvil's public first development account.
    function localAnvilPrivateKey() internal view returns (uint256 privateKey) {
        require(block.chainid == LOCAL_ANVIL_CHAIN_ID, "Local Anvil chain required");

        privateKey = vm.envUint("ANVIL_PRIVATE_KEY");
        require(vm.addr(privateKey) == LOCAL_ANVIL_ACCOUNT, "Unexpected Anvil development account");
    }
}
