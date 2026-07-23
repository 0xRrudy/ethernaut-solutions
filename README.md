# Ethernaut Foundry Solutions

[English](README.md) | [한국어](README.ko.md)

A learning repository that analyzes [OpenZeppelin Ethernaut](https://ethernaut.openzeppelin.com/) challenges and reproduces their exploits as automated Foundry tests.

Each level includes the vulnerable contract, an exploit test, and a write-up explaining the root cause, attack flow, and recommended mitigations. The goal is to document the reasoning behind each solution rather than provide answers alone.

> [!WARNING]
> This repository is intended solely for smart contract security education. Do not use these techniques against systems or contracts without explicit authorization.

## Progress

| No. | Level | Key topics | Write-up | Test |
| :---: | :--- | :--- | :---: | :---: |
| 01 | Fallback | `receive`, access control, low-level `call` | [EN](notes/en/01_Fallback.md) · [KO](notes/ko/01_Fallback.md) | Passing |

## Repository Structure

```text
.
├── src/
│   └── 01_Fallback.sol       # Original vulnerable Ethernaut contract
├── test/
│   └── 01_Fallback.t.sol     # Foundry exploit reproduction test
├── notes/
│   ├── en/
│   │   └── 01_Fallback.md    # English vulnerability write-up
│   └── ko/
│       └── 01_Fallback.md    # Korean vulnerability write-up
├── .github/workflows/
│   └── test.yml              # GitHub Actions CI
├── foundry.lock              # Dependency lock file
└── foundry.toml              # Foundry configuration
```

## File Convention

The level number and name stay consistent across the source, test, and documentation directories.

```text
src/NN_LevelName.sol
test/NN_LevelName.t.sol
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

Inspect the complete exploit call trace:

```bash
forge test --match-test testExploit -vvvv
```

Check formatting:

```bash
forge fmt --check
```

Generate a gas report:

```bash
forge test --gas-report
```

## Documentation Approach

- English is the default language for the README, source comments, tests, and portfolio presentation.
- Korean write-ups preserve detailed learning notes in the author's primary language.
- Every write-up provides links to both language versions.
- The vulnerable level logic is kept intact; explanatory comments and exploit tests are maintained separately.

## CI

GitHub Actions runs the following checks on every push and pull request:

- `forge fmt --check`
- `forge build --sizes`
- `forge test -vvv`

## Tech Stack

- Solidity
- Foundry
- Forge Standard Library
- GitHub Actions

## References

- [Ethernaut](https://ethernaut.openzeppelin.com/)
- [Ethernaut GitHub Repository](https://github.com/OpenZeppelin/ethernaut)
- [Foundry Documentation](https://getfoundry.sh/)
- [Solidity Documentation](https://docs.soliditylang.org/)

## Attribution

The original Ethernaut level contracts remain subject to the copyright and license terms of the OpenZeppelin Ethernaut project. The exploit tests and learning notes in this repository were created for educational purposes.
