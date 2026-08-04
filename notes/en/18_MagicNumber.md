# 18. Magic Number

[English](18_MagicNumber.md) | [한국어](../ko/18_MagicNumber.md)

## Objective

Deploy a solver with no more than ten bytes of runtime code that returns the number `42` for `whatIsTheMeaningOfLife()`.

## Key Concepts

- EVM bytecode
- Creation code versus runtime code
- Stack-based opcode execution
- EVM memory
- ABI-encoded return values

## Two Kinds of Deployment Code

A contract deployment transaction executes creation code. The bytes returned by that creation code become the contract's persistent runtime code.

```text
Creation code executes once during deployment
        ↓
Creation code returns a byte sequence
        ↓
The EVM stores that sequence as runtime code
        ↓
Future calls execute only the runtime code
```

The complete byte sequence used in the test is:

```text
600a600c600039600a6000f3 602a60805260206080f3
└──── creation: 12 bytes ────┘ └─ runtime: 10 bytes ─┘
```

## Runtime Code

The ten-byte runtime program is:

```text
60 2a  PUSH1 0x2a   push decimal 42
60 80  PUSH1 0x80   push memory offset 128
52     MSTORE       store 42 as a 32-byte word at memory[0x80]
60 20  PUSH1 0x20   push return length 32
60 80  PUSH1 0x80   push return offset 128
f3     RETURN       return memory[0x80 : 0xa0]
```

`MSTORE` always writes a complete 32-byte word. Returning those 32 bytes matches the ABI representation of a `uint256` whose value is `42`.

The runtime program does not inspect calldata or the four-byte function selector. Any successful call receives the same encoded value. That is sufficient for this level's required interface behavior.

## Creation Code

The first twelve bytes copy the runtime bytes embedded after them and return that copy:

```text
60 0a  PUSH1 0x0a   runtime length = 10 bytes
60 0c  PUSH1 0x0c   runtime starts at byte offset 12
60 00  PUSH1 0x00   destination memory offset = 0
39     CODECOPY     copy code[12:22] to memory[0:10]
60 0a  PUSH1 0x0a   return length = 10
60 00  PUSH1 0x00   return offset = 0
f3     RETURN       install the copied bytes as runtime code
```

The offset `0x0c` is exactly the length of the creation program itself. The creation code does not remain in the deployed contract.

## Deployment with CREATE

Solidity normally generates creation and runtime code automatically. This test passes the handcrafted bytes directly to the `CREATE` opcode:

```solidity
address solver;

assembly {
    solver := create(
        0,
        add(creationCode, 0x20),
        mload(creationCode)
    )
}
```

A dynamic `bytes` value stores its length in the first 32 bytes. `add(creationCode, 0x20)` skips that length word and points `CREATE` at the actual bytecode.

## Foundry Test

```solidity
assertNotEq(solver, address(0));

target.setSolver(solver);
assertEq(target.solver(), solver);
assertEq(solver.code.length, 10);

(bool success, bytes memory returnData) = solver.staticcall(
    abi.encodeWithSignature("whatIsTheMeaningOfLife()")
);

assertTrue(success);
assertEq(returnData.length, 32);
assertEq(abi.decode(returnData, (uint256)), 42);
```

## Root Cause

This level is not based on a conventional contract flaw. It demonstrates that high-level Solidity is optional: any valid EVM runtime program can satisfy an interface if it returns correctly encoded data.

## Recommended Engineering Practices

- Validate both runtime code size and behavior when code-size constraints matter.
- Remember that successful low-level calls do not guarantee meaningful return data.
- Check return-data length before decoding.
- Use Solidity for maintainability unless a measured constraint justifies handwritten bytecode.
- Document every opcode, stack assumption, offset, and expected return format in low-level code.

## Run the Test

```bash
forge test --match-path test/18_MagicNumber.t.sol -vvv
```

## Takeaway

Deployment code is a program that returns another program. Understanding that separation makes raw EVM bytecode much easier to reason about: creation code installs, runtime code responds.
