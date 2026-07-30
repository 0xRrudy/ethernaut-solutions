// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

/// @title Ethernaut 06 - Delegate implementation
/// @notice Provides logic that assigns its owner to the immediate caller.
contract Delegate {
    /// @notice Address currently recorded as the owner.
    address public owner;

    /// @notice Sets the initial owner.
    /// @param _owner Address assigned during deployment.
    constructor(address _owner) {
        owner = _owner;
    }

    /// @notice Replaces the owner with the immediate caller.
    function pwn() public {
        owner = msg.sender;
    }
}

/// @title Ethernaut 06 - Delegation
/// @notice Forwards unknown calls to a separate implementation with delegatecall.
/// @dev The intentionally unsafe Ethernaut fallback logic is preserved for security study.
contract Delegation {
    /// @notice Address currently recorded as the owner.
    address public owner;

    /// @dev Implementation whose code is executed in this contract's storage context.
    Delegate delegate;

    /// @notice Stores the implementation address and assigns the deployer as owner.
    /// @param _delegateAddress Address of the Delegate implementation.
    constructor(address _delegateAddress) {
        delegate = Delegate(_delegateAddress);
        owner = msg.sender;
    }

    /// @notice Forwards calldata to Delegate without restricting which function may run.
    /// @dev delegatecall preserves msg.sender and writes through Delegation's storage layout.
    fallback() external {
        (bool result,) = address(delegate).delegatecall(msg.data);
        if (result) {
            this;
        }
    }
}
