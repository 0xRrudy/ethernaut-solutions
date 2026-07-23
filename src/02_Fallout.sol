// SPDX-License-Identifier: MIT
pragma solidity ^0.6.0;

import "openzeppelin-contracts-06/math/SafeMath.sol";

/// @title Ethernaut 02 - Fallout
/// @notice Manages ETH allocations that only the owner should be able to collect.
/// @dev The intentionally vulnerable Ethernaut level logic and Solidity 0.6 compiler version are preserved.
contract Fallout {
    using SafeMath for uint256;

    /// @dev Tracks the ETH allocation associated with each address.
    mapping(address => uint256) allocations;

    /// @notice The address authorized to collect all ETH held by the contract.
    address payable public owner;

    /// @notice Intended to initialize the owner but is actually an unrestricted public function.
    /// @dev Before Solidity 0.4.22, a function matching the contract name acted as its constructor.
    ///      `Fal1out` uses the digit `1` and does not match `Fallout`. Solidity 0.6 also requires
    ///      the explicit `constructor` keyword, so this remains an ordinary callable function.
    function Fal1out() public payable {
        owner = msg.sender;
        allocations[owner] = msg.value;
    }

    /// @notice Restricts execution to the address stored as owner.
    modifier onlyOwner() {
        require(msg.sender == owner, "caller is not the owner");
        _;
    }

    /// @notice Adds the received ETH to the caller's allocation.
    function allocate() public payable {
        allocations[msg.sender] = allocations[msg.sender].add(msg.value);
    }

    /// @notice Sends an address its recorded allocation.
    /// @param allocator The address whose allocation will be transferred.
    function sendAllocation(address payable allocator) public {
        require(allocations[allocator] > 0);
        allocator.transfer(allocations[allocator]);
    }

    /// @notice Transfers the entire contract balance to the current owner.
    function collectAllocations() public onlyOwner {
        msg.sender.transfer(address(this).balance);
    }

    /// @notice Returns the recorded allocation for an address.
    /// @param allocator The address whose allocation will be queried.
    function allocatorBalance(address allocator) public view returns (uint256) {
        return allocations[allocator];
    }
}
