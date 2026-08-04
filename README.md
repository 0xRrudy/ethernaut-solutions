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
| 04 | Telephone | `tx.origin`, `msg.sender`, call chains | [EN](notes/en/04_Telephone.md) · [KO](notes/ko/04_Telephone.md) | Passing |
| 05 | Token | integer underflow, unchecked arithmetic, legacy Solidity | [EN](notes/en/05_Token.md) · [KO](notes/ko/05_Token.md) | Passing |
| 06 | Delegation | `delegatecall`, fallback, storage context | [EN](notes/en/06_Delegation.md) · [KO](notes/ko/06_Delegation.md) | Passing |
| 07 | Force | forced ETH, `selfdestruct`, balance assumptions | [EN](notes/en/07_Force.md) · [KO](notes/ko/07_Force.md) | Passing |
| 08 | Vault | private storage, storage slots, `vm.load` | [EN](notes/en/08_Vault.md) · [KO](notes/ko/08_Vault.md) | Passing |
| 09 | King | push payments, payable callbacks, state availability | [EN](notes/en/09_King.md) · [KO](notes/ko/09_King.md) | Passing |
| 10 | Re-entrancy | callback ordering, CEI, multi-version testing | [EN](notes/en/10_Reentrancy.md) · [KO](notes/ko/10_Reentrancy.md) | Passing |
| 11 | Elevator | mutable callbacks, repeated external calls | [EN](notes/en/11_Elevator.md) · [KO](notes/ko/11_Elevator.md) | Passing |
| 12 | Privacy | storage layout, packing, `vm.load` | [EN](notes/en/12_Privacy.md) · [KO](notes/ko/12_Privacy.md) | Passing |
| 13 | Gatekeeper One | `gasleft`, bit masks, `tx.origin` | [EN](notes/en/13_GatekeeperOne.md) · [KO](notes/ko/13_GatekeeperOne.md) | Passing |
| 14 | Gatekeeper Two | constructor code size, XOR, call chains | [EN](notes/en/14_GatekeeperTwo.md) · [KO](notes/ko/14_GatekeeperTwo.md) | Passing |
| 15 | Naught Coin | ERC-20 allowances, inherited transfer paths | [EN](notes/en/15_NaughtCoin.md) · [KO](notes/ko/15_NaughtCoin.md) | Passing |
| 16 | Preservation | `delegatecall`, storage layout collisions | [EN](notes/en/16_Preservation.md) · [KO](notes/ko/16_Preservation.md) | Passing |
| 17 | Recovery | CREATE addresses, RLP, contract nonces | [EN](notes/en/17_Recovery.md) · [KO](notes/ko/17_Recovery.md) | Passing |
| 18 | Magic Number | creation code, runtime code, EVM opcodes | [EN](notes/en/18_MagicNumber.md) · [KO](notes/ko/18_MagicNumber.md) | Passing |
| 19 | Alien Codex | array underflow, storage addressing, Solidity 0.5 | [EN](notes/en/19_AlienCodex.md) · [KO](notes/ko/19_AlienCodex.md) | Passing |
| 20 | Denial | gas forwarding, callback availability, EIP-150 | [EN](notes/en/20_Denial.md) · [KO](notes/ko/20_Denial.md) | Passing |

## Repository Structure

```text
.
├── src/
│   ├── 01_Fallback.sol       # Fallback level contract
│   ├── 02_Fallout.sol        # Fallout level contract (Solidity 0.6)
│   ├── 03_CoinFlip.sol       # Coin Flip level contract
│   ├── 04_Telephone.sol      # Telephone level contract
│   ├── 05_Token.sol          # Token level contract (Solidity 0.6)
│   ├── 06_Delegation.sol     # Delegation level contracts
│   ├── 07_Force.sol          # Force level contract
│   ├── 08_Vault.sol          # Vault level contract
│   ├── 09_King.sol           # King level contract
│   ├── 10_Reentrancy.sol     # Re-entrancy level contract (Solidity 0.6)
│   ├── 11_Elevator.sol       # Elevator level contract
│   ├── 12_Privacy.sol        # Privacy level contract
│   ├── 13_GatekeeperOne.sol  # Gatekeeper One level contract
│   ├── 14_GatekeeperTwo.sol  # Gatekeeper Two level contract
│   ├── 15_NaughtCoin.sol     # Naught Coin level contract
│   ├── 16_Preservation.sol   # Preservation level contracts
│   ├── 17_Recovery.sol       # Recovery level contracts
│   ├── 18_MagicNumber.sol    # Magic Number level contract
│   ├── 19_AlienCodex.sol     # Alien Codex level contract (Solidity 0.5)
│   ├── 20_Denial.sol         # Denial level contract
│   └── solvers/
│       ├── 03_CoinFlipSolver.sol
│       ├── 04_TelephoneSolver.sol
│       ├── 07_ForceSolver.sol
│       ├── 09_KingSolver.sol
│       ├── 10_ReentrancySolver.sol
│       ├── 11_ElevatorSolver.sol
│       ├── 13_GatekeeperOneSolver.sol
│       ├── 14_GatekeeperTwoSolver.sol
│       ├── 16_PreservationSolver.sol
│       └── 20_DenialSolver.sol
├── test/
│   ├── 01_Fallback.t.sol     # Fallback solution test
│   ├── 02_Fallout.t.sol      # Fallout solution test
│   ├── 03_CoinFlip.t.sol     # Coin Flip solver test
│   ├── 04_Telephone.t.sol    # Telephone solution test
│   ├── 05_Token.t.sol        # Token solution test
│   ├── 06_Delegation.t.sol   # Delegation solution test
│   ├── 07_Force.t.sol        # Force solution test
│   ├── 08_Vault.t.sol        # Vault solution test
│   ├── 09_King.t.sol         # King solution test
│   ├── 10_Reentrancy.t.sol   # Re-entrancy solution test
│   ├── 11_Elevator.t.sol     # Elevator solution test
│   ├── 12_Privacy.t.sol      # Privacy solution test
│   ├── 13_GatekeeperOne.t.sol # Gatekeeper One solution test
│   ├── 14_GatekeeperTwo.t.sol # Gatekeeper Two solution test
│   ├── 15_NaughtCoin.t.sol   # Naught Coin solution test
│   ├── 16_Preservation.t.sol # Preservation solution test
│   ├── 17_Recovery.t.sol     # Recovery solution test
│   ├── 18_MagicNumber.t.sol  # Magic Number solution test
│   ├── 19_AlienCodex.t.sol   # Alien Codex solution test
│   └── 20_Denial.t.sol       # Denial solution test
├── script/
│   ├── LocalAnvil.s.sol      # Shared local-chain safety checks
│   └── 03_CoinFlip/
│       ├── DeployCoinFlip.s.sol
│       └── SolveCoinFlip.s.sol
├── notes/
│   ├── en/
│   │   ├── 01_Fallback.md    # English Fallback write-up
│   │   ├── 02_Fallout.md     # English Fallout write-up
│   │   ├── 03_CoinFlip.md    # English Coin Flip write-up
│   │   ├── 04_Telephone.md   # English Telephone write-up
│   │   ├── 05_Token.md       # English Token write-up
│   │   ├── 06_Delegation.md  # English Delegation write-up
│   │   ├── 07_Force.md       # English Force write-up
│   │   ├── 08_Vault.md       # English Vault write-up
│   │   ├── 09_King.md        # English King write-up
│   │   ├── 10_Reentrancy.md  # English Re-entrancy write-up
│   │   ├── 11_Elevator.md    # English Elevator write-up
│   │   ├── 12_Privacy.md     # English Privacy write-up
│   │   ├── 13_GatekeeperOne.md
│   │   ├── 14_GatekeeperTwo.md
│   │   ├── 15_NaughtCoin.md
│   │   ├── 16_Preservation.md
│   │   ├── 17_Recovery.md
│   │   ├── 18_MagicNumber.md
│   │   ├── 19_AlienCodex.md
│   │   └── 20_Denial.md
│   └── ko/
│       ├── 01_Fallback.md    # Korean Fallback write-up
│       ├── 02_Fallout.md     # Korean Fallout write-up
│       ├── 03_CoinFlip.md    # Korean Coin Flip write-up
│       ├── 04_Telephone.md   # Korean Telephone write-up
│       ├── 05_Token.md       # Korean Token write-up
│       ├── 06_Delegation.md  # Korean Delegation write-up
│       ├── 07_Force.md       # Korean Force write-up
│       ├── 08_Vault.md       # Korean Vault write-up
│       ├── 09_King.md        # Korean King write-up
│       ├── 10_Reentrancy.md  # Korean Re-entrancy write-up
│       ├── 11_Elevator.md    # Korean Elevator write-up
│       ├── 12_Privacy.md     # Korean Privacy write-up
│       ├── 13_GatekeeperOne.md
│       ├── 14_GatekeeperTwo.md
│       ├── 15_NaughtCoin.md
│       ├── 16_Preservation.md
│       ├── 17_Recovery.md
│       ├── 18_MagicNumber.md
│       ├── 19_AlienCodex.md
│       └── 20_Denial.md
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

The repository keeps versioned OpenZeppelin dependencies side by side:

```text
openzeppelin-contracts-05/  OpenZeppelin Contracts v2.5.1
openzeppelin-contracts-06/  OpenZeppelin Contracts v3.4.2
openzeppelin-contracts-08/  OpenZeppelin Contracts v4.9.6
```

The versioned remappings preserve each level's original compiler constraints without forcing legacy targets and modern Foundry tests into one compiler dependency graph.

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
