# Ethernaut Foundry Solutions

[English](README.md) | [한국어](README.ko.md)

A learning repository that analyzes [OpenZeppelin Ethernaut](https://ethernaut.openzeppelin.com/) challenges and reproduces their solution paths with Foundry.

Each level includes the original challenge contract, an automated test, and a write-up explaining the root cause, solution flow, and recommended mitigations. Levels that depend on real block progression may also include an optional local Anvil workflow. The goal is to document the reasoning behind each solution rather than provide answers alone.

> [!WARNING]
> This repository is intended solely for smart contract security education. Do not use these techniques against systems or contracts without explicit authorization.

## Progress

| No. | Level | Key topics | Write-up | Test |
| :---: | :--- | :--- | :---: | :---: |
| 01 | Fallback | `receive`, access control, low-level `call` | [EN](notes/en/01_Fallback.md) · [KO](notes/ko/01_Fallback.md) | Passing |
| 02 | Fallout | constructor naming, initialization, multi-version testing | [EN](notes/en/02_Fallout.md) · [KO](notes/ko/02_Fallout.md) | Passing |
| 03 | Coin Flip | predictable randomness, `blockhash`, unit-test simulation, Anvil | [EN](notes/en/03_CoinFlip.md) · [KO](notes/ko/03_CoinFlip.md) | Passing |

## Repository Structure

```text
.
├── src/
│   ├── 01_Fallback.sol       # Fallback level contract
│   ├── 02_Fallout.sol        # Fallout level contract (Solidity 0.6)
│   ├── 03_CoinFlip.sol       # Coin Flip level contract
│   └── solvers/
│       └── 03_CoinFlipSolver.sol
├── test/
│   ├── 01_Fallback.t.sol     # Fallback solution test
│   ├── 02_Fallout.t.sol      # Fallout solution test
│   └── 03_CoinFlip.t.sol     # Coin Flip solver test
├── script/
│   ├── LocalAnvil.s.sol      # Shared local-chain safety checks
│   └── 03_CoinFlip/
│       ├── DeployCoinFlip.s.sol
│       └── SolveCoinFlip.s.sol
├── notes/
│   ├── en/
│   │   ├── 01_Fallback.md    # English Fallback write-up
│   │   ├── 02_Fallout.md     # English Fallout write-up
│   │   └── 03_CoinFlip.md    # English Coin Flip write-up
│   └── ko/
│       ├── 01_Fallback.md    # Korean Fallback write-up
│       ├── 02_Fallout.md     # Korean Fallout write-up
│       └── 03_CoinFlip.md    # Korean Coin Flip write-up
├── .github/workflows/
│   └── test.yml              # GitHub Actions CI
├── Makefile                  # Tests and optional local Anvil workflow
├── foundry.lock              # Dependency lock file
└── foundry.toml              # Foundry configuration
```

## File Convention

The level number and name stay consistent across the source, test, and documentation directories.

```text
src/NN_LevelName.sol
src/solvers/NN_LevelNameSolver.sol  # when a reusable solver is needed
test/NN_LevelName.t.sol
script/NN_LevelName/               # only when local-chain reproduction adds value
notes/en/NN_LevelName.md
notes/ko/NN_LevelName.md
```

When adding a level, the progress table in both README files should also be updated.

## Prerequisites

- [Git](https://git-scm.com/)
- [Foundry](https://getfoundry.sh/introduction/installation/)

Verify the installations:

```bash
git --version
forge --version
```

## Installation

Clone the repository with its submodules:

```bash
git clone --recurse-submodules https://github.com/0xRrudy/ethernaut-solutions.git
cd ethernaut-solutions
```

If the repository was cloned without `--recurse-submodules`, initialize the dependencies separately:

```bash
git submodule update --init --recursive
```

## Build and Test

Build all contracts:

```bash
forge build
```

Run the full test suite:

```bash
forge test
```

Run tests with detailed traces:

```bash
forge test -vvv
```

Run a specific level:

```bash
forge test --match-path test/01_Fallback.t.sol -vvv
```

Inspect the complete solution call trace:

```bash
forge test --match-test testSolve -vvvv
```

Check formatting:

```bash
forge fmt --check
```

Generate a gas report:

```bash
forge test --gas-report
```

## Optional Local Anvil Reproduction

The Coin Flip level also includes a local-chain workflow because its behavior is easier to understand when each prediction is submitted as a separate transaction in a new block.

Start a fresh Anvil node in the first terminal:

```bash
make anvil
```

In a second terminal, deploy the level and solver, submit ten predictions, and read the result:

```bash
make coinflip-deploy
make coinflip-solve
make coinflip-status
```

Use `make coinflip-step` instead of `make coinflip-solve` to submit one prediction at a time.

The Makefile accepts only `http://127.0.0.1:8545`, chain ID `31337`, and Anvil's public first development account. Its private key is a well-known local test credential and must never hold real funds or be used on a public network. Generated deployment addresses and broadcast artifacts are excluded from Git.

## Documentation Approach

- English is the default language for the README, source comments, tests, and portfolio presentation.
- Korean write-ups preserve detailed learning notes in the author's primary language.
- Every write-up provides links to both language versions.
- The original level logic is kept intact; explanatory comments, tests, and reusable solver contracts are maintained separately.
- Local scripts are added selectively when real block progression, multiple transactions, or external state materially improve the learning example.

### Legacy Compiler Compatibility

Legacy Ethernaut contracts retain their original Solidity versions. Modern tests avoid importing incompatible source files directly: they deploy the separately compiled legacy artifact with `deployCode()` and interact with it through a minimal Solidity 0.8 interface.

## CI

GitHub Actions runs the following checks on every push and pull request:

- `forge fmt --check`
- `forge build --sizes`
- `forge test -vvv`

## Tech Stack

- Solidity
- Foundry
- Forge Standard Library
- OpenZeppelin Contracts
- GitHub Actions

## References

- [Ethernaut](https://ethernaut.openzeppelin.com/)
- [Ethernaut GitHub Repository](https://github.com/OpenZeppelin/ethernaut)
- [Foundry Documentation](https://getfoundry.sh/)
- [Solidity Documentation](https://docs.soliditylang.org/)

## Attribution

The original Ethernaut level contracts remain subject to the copyright and license terms of the OpenZeppelin Ethernaut project. The tests, solver contracts, scripts, and learning notes in this repository were created for educational purposes.
