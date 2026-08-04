# 19. Alien Codex

[English](19_AlienCodex.md) | [한국어](../ko/19_AlienCodex.md)

## Objective

Use the legacy array behavior to change the target's inherited `owner` to the player.

## Key Concepts

- Solidity 0.5 arithmetic underflow
- Inheritance and storage packing
- Dynamic-array storage addressing
- Arithmetic modulo `2^256`
- Multi-compiler Foundry tests

## Storage Layout

The target inherits OpenZeppelin Contracts 2.5.1 `Ownable`, whose `_owner` is an `address`. The derived contract then declares a `bool` and a dynamic array.

Small adjacent values can share one 32-byte slot, including across inherited storage layout. The relevant layout is:

| Slot | Contents |
| :---: | :--- |
| `0` | `_owner` in the low 20 bytes, followed by `contact` |
| `1` | `codex.length` |
| `keccak256(1) + i` | `codex[i]` |

The dynamic array's declared slot stores only its length. Its element data begins at:

```text
P = keccak256(abi.encode(uint256(1)))
```

## Expanding the Reachable Array Range

The level uses Solidity 0.5, where arithmetic does not automatically revert on underflow:

```solidity
function retract() public contacted {
    codex.length--;
}
```

After `makeContact()`, the initially empty array can call `retract()`. Its length changes as follows:

```text
0 - 1 mod 2^256 = 2^256 - 1
```

Almost the complete storage address space is now accepted as an in-bounds array index.

## Mapping an Array Index to Slot Zero

Array element `i` is stored at:

```text
slot(i) = P + i mod 2^256
```

To make that slot equal zero:

```text
P + i ≡ 0 mod 2^256
i ≡ -P mod 2^256
i = 2^256 - P
```

The Solidity 0.8 test must place this wrapping arithmetic inside `unchecked`:

```solidity
uint256 ownerSlotIndex;
unchecked {
    ownerSlotIndex = 0 - codexDataSlot;
}
```

## Writing the Owner Value

The player address is placed in the low 20 bytes of a full storage word:

```solidity
bytes32 playerAsBytes32 = bytes32(uint256(uint160(player)));
target.revise(ownerSlotIndex, playerAsBytes32);
```

`revise()` believes it is writing an array element, but the calculated element slot wraps to slot `0`. `Ownable.owner()` then reads the low 20 bytes as the new owner.

Writing the complete zero-padded word also clears the packed `contact` byte. This does not affect the completion condition, and the test explicitly verifies the resulting value.

## Solution Flow

```text
Player calls makeContact()
        ↓
Player calls retract() on an empty Solidity 0.5 array
        ↓
codex.length underflows to 2^256 - 1
        ↓
Compute P = keccak256(slot 1)
        ↓
Compute index = 2^256 - P
        ↓
codex[index] resolves to storage slot 0
        ↓
Write the player address as a 32-byte word
        ↓
Inherited owner becomes player
```

## Multi-Compiler Foundry Test

The target retains Solidity 0.5 while the test uses Solidity 0.8 and the latest `forge-std`. The test therefore does not import the legacy source directly. It deploys the separately compiled artifact and uses a minimal interface:

```solidity
target = IAlienCodex(
    deployCode("19_AlienCodex.sol:AlienCodex")
);
```

Final checks:

```solidity
assertEq(target.owner(), player);
assertFalse(target.contact());
```

## Root Cause

Unchecked length underflow turns a bounded dynamic array into an almost arbitrary storage-writing mechanism. The array address formula then allows a chosen index to reach the inherited authorization slot.

## Recommended Mitigations

- Use Solidity 0.8 or checked arithmetic for length and index updates.
- Never reduce an array length below zero; use `pop()` with an explicit nonempty check.
- Restrict functions that write arbitrary array indices.
- Include inherited variables when reviewing storage layout.
- Test storage invariants and boundary conditions, especially when maintaining legacy contracts.
- Migrate legacy code instead of relying only on caller discipline.

## Run the Test

```bash
forge test --match-path test/19_AlienCodex.t.sol -vvv
```

## Takeaway

Dynamic arrays translate indexes into storage slots with modular arithmetic. If a legacy underflow removes the length boundary, an array write can reach unrelated state, including inherited ownership data.
