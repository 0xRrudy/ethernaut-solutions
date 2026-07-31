// SPDX-License-Identifier: MIT
pragma solidity ^0.6.12;

import "openzeppelin-contracts-06/math/SafeMath.sol";

/// @title Ethernaut 10 - Re-entrancy
/// @notice Records ETH balances and allows callers to withdraw them.
/// @dev The original Ethernaut level logic and Solidity 0.6 version are preserved.
contract Reentrance {
    using SafeMath for uint256;

    /// @notice Recorded ETH balance for each account.
    mapping(address => uint256) public balances;

    /// @notice Adds the supplied ETH to an account's recorded balance.
    function donate(address _to) public payable {
        balances[_to] = balances[_to].add(msg.value);
    }

    /// @notice Returns an account's recorded balance.
    function balanceOf(address _who) public view returns (uint256 balance) {
        return balances[_who];
    }

    /// @notice Sends ETH before reducing the caller's recorded balance.
    /// @dev The external callback occurs before the accounting update.
    function withdraw(uint256 _amount) public {
        if (balances[msg.sender] >= _amount) {
            (bool result,) = msg.sender.call{value: _amount}("");
            if (result) {
                _amount;
            }
            balances[msg.sender] -= _amount;
        }
    }

    /// @notice Allows the level instance to receive ETH directly.
    receive() external payable {}
}
