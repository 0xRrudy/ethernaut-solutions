// SPDX-License-Identifier: MIT
pragma solidity ^0.6.0;

/// @title Ethernaut 05 - Token
/// @notice Implements a minimal token balance ledger and transfer function.
/// @dev The intentionally vulnerable Ethernaut logic and Solidity 0.6 compiler version are preserved.
contract Token {
    /// @dev Stores the token balance assigned to each address.
    mapping(address => uint256) balances;

    /// @notice Total number of tokens created at deployment.
    uint256 public totalSupply;

    /// @notice Assigns the full initial supply to the deployer.
    /// @param _initialSupply Number of tokens created during deployment.
    constructor(uint256 _initialSupply) public {
        balances[msg.sender] = totalSupply = _initialSupply;
    }

    /// @notice Transfers tokens from the caller to another address.
    /// @dev In Solidity 0.6, subtracting more than the caller owns wraps instead of reverting.
    ///      The unsigned result is always greater than or equal to zero, so the require statement
    ///      does not prevent an insufficient-balance transfer.
    /// @param _to Address that receives the tokens.
    /// @param _value Number of tokens to transfer.
    /// @return True when the transfer completes.
    function transfer(address _to, uint256 _value) public returns (bool) {
        require(balances[msg.sender] - _value >= 0);
        balances[msg.sender] -= _value;
        balances[_to] += _value;
        return true;
    }

    /// @notice Returns the token balance assigned to an address.
    /// @param _owner Address whose balance will be queried.
    /// @return balance Token balance held by the address.
    function balanceOf(address _owner) public view returns (uint256 balance) {
        return balances[_owner];
    }
}
