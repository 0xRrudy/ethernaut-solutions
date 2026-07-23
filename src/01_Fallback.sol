// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

/// @title Ethernaut 01 - Fallback
/// @notice Records contributions and lets the owner withdraw the contract balance.
/// @dev The intentionally vulnerable Ethernaut level logic is preserved for study.
contract Fallback {
    /// @notice Tracks the cumulative contribution made by each address.
    mapping(address => uint256) public contributions;

    /// @notice The current contract owner.
    address public owner;

    /// @notice Sets the deployer as owner and records a large initial contribution.
    constructor() {
        owner = msg.sender;
        contributions[msg.sender] = 1000 * (1 ether);
    }

    /// @notice Restricts execution to the current owner.
    modifier onlyOwner() {
        require(msg.sender == owner, "caller is not the owner");
        _;
    }

    /// @notice Lets the caller contribute less than 0.001 ether.
    /// @dev Ownership changes when the caller's total exceeds the owner's contribution.
    function contribute() public payable {
        require(msg.value < 0.001 ether);
        contributions[msg.sender] += msg.value;
        if (contributions[msg.sender] > contributions[owner]) {
            owner = msg.sender;
        }
    }

    /// @notice Returns the caller's cumulative contribution.
    function getContribution() public view returns (uint256) {
        return contributions[msg.sender];
    }

    /// @notice Transfers the entire contract balance to the current owner.
    function withdraw() public onlyOwner {
        payable(owner).transfer(address(this).balance);
    }

    /// @notice Executes when the contract receives ETH with empty calldata.
    /// @dev This is the core vulnerability: any prior contributor becomes owner by
    ///      sending additional ETH, without authorization from the current owner.
    receive() external payable {
        require(msg.value > 0 && contributions[msg.sender] > 0);
        owner = msg.sender;
    }
}
