# 15. Naught Coin

[English](15_NaughtCoin.md) | [한국어](../ko/15_NaughtCoin.md)

## Objective

Move the player's complete token balance before the ten-year transfer lock expires.

## Key Concepts

- ERC-20 allowances
- `transfer` versus `transferFrom`
- Inherited functionality
- Shared internal transfer paths
- Invariant-level restrictions

## Contract Analysis

The target overrides only `transfer()` and applies a time-lock modifier when the caller is the initial player:

```solidity
function transfer(
    address _to,
    uint256 _value
) public override lockTokens returns (bool) {
    super.transfer(_to, _value);
}
```

The inherited ERC-20 contract still exposes two other important functions:

```text
approve(spender, amount)
transferFrom(owner, recipient, amount)
```

`approve()` authorizes a spender. That spender can then call `transferFrom()` to move tokens from the owner's balance. Because the target did not override `transferFrom()` or enforce the lock in a shared internal transfer hook, this path does not execute `lockTokens`.

## ERC-20 Call Paths

The two paths have different external entry points:

```text
Direct path
player → transfer(recipient, amount) → lockTokens → revert before timeLock

Allowance path
player → approve(spender, amount)
spender → transferFrom(player, spender, amount) → inherited ERC-20 logic → success
```

The intended policy is “the player's tokens cannot move before the deadline,” but the implementation enforces only “the player cannot call this one function before the deadline.” A policy that applies to a state transition must cover every function capable of producing that transition.

## Solution Flow

```text
Read the player's complete ERC-20 balance
        ↓
Confirm direct transfer is currently locked
        ↓
Player approves a separate spender for the full balance
        ↓
Spender calls transferFrom(player, spender, full balance)
        ↓
Inherited ERC-20 accounting moves the tokens
        ↓
Player balance becomes zero
```

## Foundry Test

```solidity
uint256 amount = target.balanceOf(player);

vm.startPrank(player);
vm.expectRevert();
target.transfer(spender, 1);
assertTrue(target.approve(spender, amount));
vm.stopPrank();

vm.prank(spender);
assertTrue(target.transferFrom(player, spender, amount));

assertEq(target.balanceOf(player), 0);
assertEq(target.balanceOf(spender), amount);
assertEq(target.allowance(player, spender), 0);
```

The direct-transfer check demonstrates that the time lock is active; the remaining assertions prove the alternate ERC-20 path completed the level.

## Root Cause

The restriction is attached to one public wrapper instead of the common token movement mechanism. Inherited methods remain capable of changing the same balances without applying the intended policy.

## Recommended Mitigations

- Enforce transfer restrictions in a shared internal hook used by both `transfer()` and `transferFrom()`.
- For OpenZeppelin Contracts 4.x, use the appropriate transfer hook or override the shared internal transfer path.
- Review inherited public functions whenever extending a token standard.
- Write invariant tests covering every entry point that can move balances.
- Return the inherited Boolean result from ERC-20 wrapper functions to preserve interface semantics.

## Run the Test

```bash
forge test --match-path test/15_NaughtCoin.t.sol -vvv
```

## Takeaway

Function-level checks do not automatically enforce state-level policies. With composable standards such as ERC-20, every inherited route to the protected state transition must be considered.
