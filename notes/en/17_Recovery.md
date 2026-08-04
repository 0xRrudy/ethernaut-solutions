# 17. Recovery

[English](17_Recovery.md) | [한국어](../ko/17_Recovery.md)

## Objective

Reconstruct the address of the generated `SimpleToken` contract and return its Ether balance to the player.

## Key Concepts

- Deterministic `CREATE` addresses
- Contract account nonces
- Recursive Length Prefix (RLP) encoding
- Address truncation from `keccak256`
- Modern `SELFDESTRUCT` behavior

## Contract Analysis

`Recovery.generateToken()` creates a new contract but does not store or return its address:

```solidity
function generateToken(
    string memory _name,
    uint256 _initialSupply
) public {
    new SimpleToken(_name, msg.sender, _initialSupply);
}
```

The address is not random or lost from the EVM. A contract created with the `CREATE` opcode has a deterministic address derived from its creator and the creator's nonce.

## CREATE Address Formula

For `CREATE`, the address is:

```text
createdAddress = last20bytes(
    keccak256(RLP([creatorAddress, creatorNonce]))
)
```

`Recovery` creates its first child with nonce `1`. For a 20-byte creator address and a one-byte nonce equal to `1`, the RLP encoding is:

```text
0xd6 || 0x94 || creatorAddress || 0x01
```

| Bytes | Meaning |
| :--- | :--- |
| `0xd6` | RLP list prefix for the 22-byte payload |
| `0x94` | RLP string prefix for a 20-byte address |
| `creatorAddress` | Address of the `Recovery` contract |
| `0x01` | Creator nonce used for its first `CREATE` |

The test hashes these bytes and keeps the low 20 bytes:

```solidity
bytes32 addressHash = keccak256(
    abi.encodePacked(
        bytes1(0xd6),
        bytes1(0x94),
        creator,
        bytes1(0x01)
    )
);

address tokenAddress = address(uint160(uint256(addressHash)));
```

RLP encoding changes when the nonce requires more bytes, so this compact expression is intentionally specific to the first child contract.

## Solution Flow

```text
Recovery creates its first SimpleToken with CREATE nonce 1
        ↓
Rebuild RLP([Recovery address, 1])
        ↓
Hash the encoded bytes with keccak256
        ↓
Keep the low 20 bytes as the SimpleToken address
        ↓
Confirm the address holds 0.001 ETH
        ↓
Call SimpleToken.destroy(player)
        ↓
Verify token balance is zero and player received the ETH
```

## Foundry Test

The manual calculation is cross-checked against Foundry's address helper:

```solidity
assertEq(
    tokenAddress,
    vm.computeCreateAddress(address(target), 1)
);
assertEq(tokenAddress.balance, 0.001 ether);

uint256 playerBalanceBefore = player.balance;

vm.prank(player);
SimpleToken(payable(tokenAddress)).destroy(payable(player));

assertEq(tokenAddress.balance, 0);
assertEq(player.balance, playerBalanceBefore + 0.001 ether);
```

## SELFDESTRUCT Note

Modern EVM rules restrict when `SELFDESTRUCT` removes a contract's code and storage. Its balance-transfer effect remains: the remaining Ether is sent to the beneficiary. This level's completion condition depends on recovering the Ether, not on assuming permanent code deletion.

## Root Cause

The application does not retain or emit the generated address, but deterministic contract creation still makes the address recoverable from public state and creation order.

## Recommended Mitigations

- Return the created address from factory functions.
- Emit an event containing the created address and relevant metadata.
- Store child addresses when the application needs later discovery.
- Use access control for lifecycle functions that move a contract's entire balance.
- Do not design modern systems around code deletion assumptions from historical `SELFDESTRUCT` behavior.

## Run the Test

```bash
forge test --match-path test/17_Recovery.t.sol -vvv
```

## Takeaway

Contract addresses created with `CREATE` are deterministic. Even without a stored reference, the creator address and nonce are enough to reconstruct the first child address.
