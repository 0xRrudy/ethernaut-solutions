# 12. Privacy

[English](12_Privacy.md) | [한국어](../ko/12_Privacy.md)

## Objective

Derive the key stored in the target and set `locked` to `false`.

## Key Concepts

- EVM storage visibility
- Solidity storage packing
- Fixed-size arrays
- Explicit type truncation
- Foundry's `vm.load`

## Contract Analysis

The target marks several values as `private`, including a three-element `bytes32` array:

```solidity
bytes32[3] private data;

function unlock(bytes16 _key) public {
    require(_key == bytes16(data[2]));
    locked = false;
}
```

`private` prevents other Solidity contracts from accessing the variable through a generated getter. It does not encrypt the underlying storage. Every full node must be able to read contract storage to execute and verify transactions.

## Storage Layout

Solidity assigns storage slots in declaration order and packs adjacent values when they fit into one 32-byte word.

| Slot | Contents |
| :---: | :--- |
| `0` | `locked` (`bool`) |
| `1` | `ID` (`uint256`) |
| `2` | `flattening`, `denomination`, and `awkwardness` packed together |
| `3` | `data[0]` |
| `4` | `data[1]` |
| `5` | `data[2]` |

The fixed-size array occupies one complete slot per `bytes32` element. The unlock key therefore comes from slot `5`.

## Bytes Conversion

The expression `bytes16(data[2])` keeps the first 16 bytes of the `bytes32` value. The test must reproduce the same conversion after reading the complete word:

```solidity
bytes32 storedWord = vm.load(address(target), bytes32(uint256(5)));
bytes16 key = bytes16(storedWord);
```

This is different from converting an integer to a smaller integer, which keeps the least-significant bits. Fixed-size byte arrays are aligned and truncated according to their byte-array conversion rules.

## Solution Flow

```text
Determine Solidity's declaration-order storage layout
        ↓
Locate data[2] at slot 5
        ↓
Read the complete 32-byte word with vm.load
        ↓
Convert it with bytes16(...), matching unlock()
        ↓
Call unlock(key) as the player
        ↓
Verify locked == false
```

## Foundry Test

```solidity
bytes16 key = bytes16(
    vm.load(address(target), bytes32(uint256(5)))
);

vm.prank(player);
target.unlock(key);

assertFalse(target.locked());
```

`vm.load` is a local testing cheatcode that exposes the same public blockchain state a node or RPC storage query can read.

## Root Cause

The target treats a `private` storage value as a secret. Solidity visibility controls contract-level access, not blockchain-level confidentiality.

## Recommended Mitigations

- Never store plaintext secrets or reusable credentials on a public blockchain.
- Store a commitment or hash when only later verification is required.
- Use commit-reveal schemes when a value can be disclosed after a protected phase.
- Keep genuinely confidential material off-chain or use an appropriate cryptographic protocol.
- Document storage layout assumptions and test upgrades carefully because packing affects slot positions.

## Run the Test

```bash
forge test --match-path test/12_Privacy.t.sol -vvv
```

## Takeaway

`private` means “no Solidity getter,” not “hidden from observers.” Contract storage is public data, and packing rules only change where that data is located.
