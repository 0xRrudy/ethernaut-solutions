# 14. Gatekeeper Two

[English](14_GatekeeperTwo.md) | [한국어](../ko/14_GatekeeperTwo.md)

## Objective

Satisfy all three gates and record the player as `entrant`.

## Key Concepts

- Constructor-time execution
- Contract code size
- `msg.sender` and `tx.origin`
- `keccak256`
- XOR identities

## Gate One: Separate Sender and Origin

```solidity
require(msg.sender != tx.origin);
```

The player deploys `GatekeeperTwoSolver`. During the solver constructor, the solver calls the target:

```text
tx.origin  = player
msg.sender = GatekeeperTwoSolver
```

This call chain satisfies the first gate.

## Gate Two: Call During Construction

```solidity
uint256 x;
assembly {
    x := extcodesize(caller())
}
require(x == 0);
```

While a contract constructor is executing, the address already exists and can make external calls, but its final runtime bytecode has not yet been stored at that address. `EXTCODESIZE` therefore returns `0` for the solver during its own construction.

After the constructor returns, the runtime code is installed and the same check would no longer return zero. Calling the target from the constructor is therefore essential.

Code size is not a reliable identity test. Externally owned accounts, contracts under construction, and some lifecycle edge cases can all have zero observable code size.

## Gate Three: Construct the XOR Complement

The target computes a 64-bit hash fragment `H` and requires:

```text
H XOR key = 2^64 - 1
```

The required key is the bitwise complement of `H`:

```text
key = (2^64 - 1) XOR H
```

This follows from the XOR identities `A XOR A = 0` and `A XOR 0 = A`:

```text
H XOR ((2^64 - 1) XOR H)
= (H XOR H) XOR (2^64 - 1)
= 0 XOR (2^64 - 1)
= 2^64 - 1
```

The solver derives `H` from its own address because that address is `msg.sender` inside the target:

```solidity
bytes8 key = bytes8(
    type(uint64).max ^
    uint64(bytes8(keccak256(abi.encodePacked(address(this)))))
);
```

## Solution Flow

```text
Player starts deployment of GatekeeperTwoSolver
        ↓
Solver constructor calculates the XOR-complement key
        ↓
Constructor calls GatekeeperTwo.enter(key)
        ↓
msg.sender differs from tx.origin
        ↓
Solver runtime code is not installed yet, so EXTCODESIZE is 0
        ↓
The key XOR hash equals uint64.max
        ↓
Target records entrant = player
        ↓
Solver constructor finishes and runtime code is installed
```

## Foundry Test

```solidity
assertEq(target.entrant(), address(0));

vm.prank(player, player);
solver = new GatekeeperTwoSolver(address(target));

assertEq(target.entrant(), player);
```

## Root Cause

The target uses observable code size and call-chain shape as access conditions. Code size changes during construction and cannot prove whether an address is a person, a contract, or an authorized participant.

## Recommended Mitigations

- Do not use `EXTCODESIZE` or `address.code.length` to block contract callers.
- Use explicit permissions, signatures, allowlists, or role-based access control.
- Design integrations to support contract wallets and account abstraction.
- Treat constructor-time calls as normal external interactions in tests and threat models.

## Run the Test

```bash
forge test --match-path test/14_GatekeeperTwo.t.sol -vvv
```

## Takeaway

A contract can call other contracts before its runtime code exists. Code size describes one moment in an address lifecycle; it does not establish identity or authorization.
