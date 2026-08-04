# 20. Denial

[English](20_Denial.md) | [한국어](../ko/20_Denial.md)

## Objective

Configure a withdrawal partner that prevents `withdraw()` from completing when the transaction supplies no more than one million gas.

## Key Concepts

- Unbounded gas forwarding
- EIP-150's 63/64 gas rule
- Out-of-gas behavior in low-level calls
- Push-based payments
- Availability of critical state transitions

## Contract Analysis

`withdraw()` calculates one percent of the contract balance, calls an arbitrary partner, and only afterward pays the owner and updates accounting:

```solidity
function withdraw() public {
    uint256 amountToSend = address(this).balance / 100;

    partner.call{value: amountToSend}("");
    payable(owner).transfer(amountToSend);

    timeLastWithdrawn = block.timestamp;
    withdrawPartnerBalances[partner] += amountToSend;
}
```

The partner address is unrestricted and can point to any contract. The low-level call does not specify a gas limit, so it forwards almost all gas still available at that point.

## EIP-150 Gas Forwarding

Under EIP-150, a nested call cannot receive more than 63/64 of the caller's remaining gas. Approximately 1/64 stays in the caller's frame:

```text
gas forwarded to partner ≈ remaining gas × 63 / 64
gas retained by Denial    ≈ remaining gas ×  1 / 64
```

This retained fraction prevents the caller from always losing literally every gas unit to the callee. It does not guarantee that the caller has enough gas for expensive work after the call.

With a one-million-gas withdrawal, the trace shows that the partner receives roughly 975,000 gas. Only a small fraction remains in `Denial` after the partner call.

## Revert Versus Gas Exhaustion

The target's comment assumes that a partner revert is harmless because the low-level call returns `false` and execution continues. That is true when the callback reverts promptly: unused gas is returned to the caller.

The solver instead keeps executing until its complete forwarded allowance is exhausted:

```solidity
receive() external payable {
    while (true) {}
}
```

The nested call still reports failure, but it returns almost no unused gas. The caller retains only its EIP-150 reserve. That reserve is insufficient to finish the following value transfer and storage writes.

The outer `withdraw()` therefore also runs out of gas. Because the complete transaction reverts, the earlier ETH transfer to the partner is rolled back and the target balance remains unchanged.

## Solution Flow

```text
Target holds 1 ETH
        ↓
Set DenialSolver as the withdrawal partner
        ↓
Player calls withdraw() with 1,000,000 gas
        ↓
Denial forwards approximately 63/64 of its remaining gas
        ↓
Solver callback loops until the forwarded gas is exhausted
        ↓
Low-level partner call returns false with very little gas left
        ↓
Denial cannot finish owner payment and accounting updates
        ↓
Outer call fails and all value transfers roll back
```

## Foundry Test

The test captures the outer call result instead of allowing the expected failure to terminate the test:

```solidity
address owner = target.owner();
uint256 ownerBalanceBefore = owner.balance;

assertEq(target.partner(), address(solver));
assertEq(target.contractBalance(), 1 ether);

vm.prank(player);
(bool success,) = address(target).call{gas: 1_000_000}(
    abi.encodeWithSelector(Denial.withdraw.selector)
);

assertFalse(success);
assertEq(target.contractBalance(), 1 ether);
assertEq(owner.balance, ownerBalanceBefore);
```

These assertions prove not only that the call failed, but also that the target still holds its funds and the owner received nothing.

## Root Cause

A critical state transition makes an unrestricted call to an address selected by external input and forwards nearly all available gas before completing the owner payment and accounting updates. The partner therefore controls whether enough execution resources remain for the function to finish.

## Recommended Mitigations

- Use pull-based payments so each recipient withdraws independently.
- Avoid making one recipient's callback a prerequisite for payments to other recipients.
- Apply a deliberate gas limit when invoking an untrusted callback.
- Handle failed partner payments through explicit accounting rather than continuing a coupled push-payment sequence.
- Perform critical state updates before external interaction where the intended invariant permits it.
- Test callbacks that return, revert immediately, and consume their full gas allowance.
- Remember that merely checking the low-level call's Boolean result does not restore gas already consumed by the callee.

## Run the Test

```bash
forge test --match-path test/20_Denial.t.sol -vvv
```

For the complete gas trace:

```bash
forge test --match-path test/20_Denial.t.sol -vvvv
```

## Takeaway

Ignoring a failed low-level call may preserve control flow, but it cannot preserve gas. An untrusted callback that receives almost all remaining gas can prevent every state transition placed after it from completing.
