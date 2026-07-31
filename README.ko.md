# Ethernaut Foundry 풀이

[English](README.md) | [한국어](README.ko.md)

OpenZeppelin의 [Ethernaut](https://ethernaut.openzeppelin.com/) 워게임을 분석하고 풀이 과정을 Foundry로 재현한 학습 저장소입니다.

각 레벨의 원본 컨트랙트, 자동화 테스트, 풀이 노트를 함께 관리합니다. 실제 블록 진행이 중요한 레벨에는 선택적으로 로컬 Anvil 실행 환경도 추가합니다. 단순 정답뿐 아니라 문제의 원인, 풀이 흐름, 완화 방법까지 기록하는 것을 목표로 합니다.

> [!WARNING]
> 이 저장소의 코드는 스마트 컨트랙트 보안 학습을 위한 것입니다. 명시적인 허가 없이 실제 시스템이나 컨트랙트에 사용하면 안 됩니다.

## 진행 현황

| 번호 | 레벨 | 핵심 주제 | 풀이 | 테스트 |
| :---: | :--- | :--- | :---: | :---: |
| 01 | Fallback | `receive`, 접근 제어, 저수준 `call` | [EN](notes/en/01_Fallback.md) · [KO](notes/ko/01_Fallback.md) | 통과 |
| 02 | Fallout | 생성자 이름, 초기화, 다중 버전 테스트 | [EN](notes/en/02_Fallout.md) · [KO](notes/ko/02_Fallout.md) | 통과 |
| 03 | Coin Flip | 예측 가능한 난수, `blockhash`, 단위 테스트, Anvil | [EN](notes/en/03_CoinFlip.md) · [KO](notes/ko/03_CoinFlip.md) | 통과 |
| 04 | Telephone | `tx.origin`, `msg.sender`, 호출 체인 | [EN](notes/en/04_Telephone.md) · [KO](notes/ko/04_Telephone.md) | 통과 |
| 05 | Token | 정수 언더플로, 검사 없는 산술 연산, 구버전 Solidity | [EN](notes/en/05_Token.md) · [KO](notes/ko/05_Token.md) | 통과 |
| 06 | Delegation | `delegatecall`, fallback, 스토리지 문맥 | [EN](notes/en/06_Delegation.md) · [KO](notes/ko/06_Delegation.md) | 통과 |
| 07 | Force | 강제 ETH 전송, `selfdestruct`, 잔액 가정 | [EN](notes/en/07_Force.md) · [KO](notes/ko/07_Force.md) | 통과 |
| 08 | Vault | private 스토리지, 스토리지 슬롯, `vm.load` | [EN](notes/en/08_Vault.md) · [KO](notes/ko/08_Vault.md) | 통과 |
| 09 | King | 푸시 방식 지급, payable 콜백, 상태 가용성 | [EN](notes/en/09_King.md) · [KO](notes/ko/09_King.md) | 통과 |
| 10 | Re-entrancy | 콜백 실행 순서, CEI, 다중 버전 테스트 | [EN](notes/en/10_Reentrancy.md) · [KO](notes/ko/10_Reentrancy.md) | 통과 |

## 저장소 구조

```text
.
├── src/
│   ├── 01_Fallback.sol       # Fallback 레벨 컨트랙트
│   ├── 02_Fallout.sol        # Fallout 레벨 컨트랙트 (Solidity 0.6)
│   ├── 03_CoinFlip.sol       # Coin Flip 레벨 컨트랙트
│   ├── 04_Telephone.sol      # Telephone 레벨 컨트랙트
│   ├── 05_Token.sol          # Token 레벨 컨트랙트 (Solidity 0.6)
│   ├── 06_Delegation.sol     # Delegation 레벨 컨트랙트
│   ├── 07_Force.sol          # Force 레벨 컨트랙트
│   ├── 08_Vault.sol          # Vault 레벨 컨트랙트
│   ├── 09_King.sol           # King 레벨 컨트랙트
│   ├── 10_Reentrancy.sol     # Re-entrancy 레벨 컨트랙트 (Solidity 0.6)
│   └── solvers/
│       ├── 03_CoinFlipSolver.sol
│       ├── 04_TelephoneSolver.sol
│       ├── 07_ForceSolver.sol
│       ├── 09_KingSolver.sol
│       └── 10_ReentrancySolver.sol
├── test/
│   ├── 01_Fallback.t.sol     # Fallback 풀이 테스트
│   ├── 02_Fallout.t.sol      # Fallout 풀이 테스트
│   ├── 03_CoinFlip.t.sol     # Coin Flip 솔버 테스트
│   ├── 04_Telephone.t.sol    # Telephone 풀이 테스트
│   ├── 05_Token.t.sol        # Token 풀이 테스트
│   ├── 06_Delegation.t.sol   # Delegation 풀이 테스트
│   ├── 07_Force.t.sol        # Force 풀이 테스트
│   ├── 08_Vault.t.sol        # Vault 풀이 테스트
│   ├── 09_King.t.sol         # King 풀이 테스트
│   └── 10_Reentrancy.t.sol   # Re-entrancy 풀이 테스트
├── script/
│   ├── LocalAnvil.s.sol      # 로컬 체인 공통 안전 검사
│   └── 03_CoinFlip/
│       ├── DeployCoinFlip.s.sol
│       └── SolveCoinFlip.s.sol
├── notes/
│   ├── en/
│   │   ├── 01_Fallback.md    # Fallback 영문 분석
│   │   ├── 02_Fallout.md     # Fallout 영문 분석
│   │   ├── 03_CoinFlip.md    # Coin Flip 영문 분석
│   │   ├── 04_Telephone.md   # Telephone 영문 분석
│   │   ├── 05_Token.md       # Token 영문 분석
│   │   ├── 06_Delegation.md  # Delegation 영문 분석
│   │   ├── 07_Force.md       # Force 영문 분석
│   │   ├── 08_Vault.md       # Vault 영문 분석
│   │   ├── 09_King.md        # King 영문 분석
│   │   └── 10_Reentrancy.md  # Re-entrancy 영문 분석
│   └── ko/
│       ├── 01_Fallback.md    # Fallback 한글 분석
│       ├── 02_Fallout.md     # Fallout 한글 분석
│       ├── 03_CoinFlip.md    # Coin Flip 한글 분석
│       ├── 04_Telephone.md   # Telephone 한글 분석
│       ├── 05_Token.md       # Token 한글 분석
│       ├── 06_Delegation.md  # Delegation 한글 분석
│       ├── 07_Force.md       # Force 한글 분석
│       ├── 08_Vault.md       # Vault 한글 분석
│       ├── 09_King.md        # King 한글 분석
│       └── 10_Reentrancy.md  # Re-entrancy 한글 분석
├── .github/workflows/
│   └── test.yml              # GitHub Actions CI
├── Makefile                  # 테스트 및 선택적 Anvil 실행 명령
├── foundry.lock              # 의존성 잠금 파일
└── foundry.toml              # Foundry 설정
```

## 파일 작성 규칙

레벨 번호와 이름을 소스, 테스트, 문서 폴더에서 동일하게 유지합니다.

```text
src/NN_LevelName.sol
src/solvers/NN_LevelNameSolver.sol  # 재사용 가능한 솔버가 필요할 때
test/NN_LevelName.t.sol
script/NN_LevelName/               # 로컬 체인 재현이 유용할 때만
notes/en/NN_LevelName.md
notes/ko/NN_LevelName.md
```

새로운 레벨을 추가할 때는 두 README의 진행 현황 표도 함께 갱신합니다.

## 사전 준비

- [Git](https://git-scm.com/)
- [Foundry](https://getfoundry.sh/introduction/installation/)

설치 확인:

```bash
git --version
forge --version
```

## 설치

서브모듈을 포함해 저장소를 클론합니다.

```bash
git clone --recurse-submodules https://github.com/0xRrudy/ethernaut-solutions.git
cd ethernaut-solutions
```

이미 일반 clone을 사용했다면 의존성을 초기화합니다.

```bash
git submodule update --init --recursive
```

## 빌드 및 테스트

전체 컨트랙트 빌드:

```bash
forge build
```

전체 테스트:

```bash
forge test
```

상세 실행 추적:

```bash
forge test -vvv
```

특정 레벨만 실행:

```bash
forge test --match-path test/01_Fallback.t.sol -vvv
```

풀이 테스트의 전체 호출 추적:

```bash
forge test --match-test testSolve -vvvv
```

포맷 검사:

```bash
forge fmt --check
```

가스 사용량 확인:

```bash
forge test --gas-report
```

## 선택적 로컬 Anvil 재현

Coin Flip은 새로운 블록마다 별도 트랜잭션을 제출하는 과정을 확인하면 동작을 더 정확히 이해할 수 있어 로컬 체인 실행 방법도 제공합니다.

첫 번째 터미널에서 새로운 Anvil 노드를 실행합니다.

```bash
make anvil
```

두 번째 터미널에서 레벨과 솔버를 배포하고, 예측을 10회 제출한 뒤 결과를 확인합니다.

```bash
make coinflip-deploy
make coinflip-solve
make coinflip-status
```

한 번씩 과정을 확인하려면 `make coinflip-solve` 대신 `make coinflip-step`을 실행합니다.

Makefile은 `http://127.0.0.1:8545`, 체인 ID `31337`, Anvil의 공개된 첫 번째 개발 계정만 허용합니다. 여기에 적힌 개인 키는 누구나 알고 있는 로컬 테스트 전용 값이므로 실제 자금을 보관하거나 공개 네트워크에서 사용하면 안 됩니다. 로컬 배포 주소와 실행 기록은 Git에서 제외됩니다.

## 문서화 원칙

- README, 소스 주석, 테스트 주석, 포트폴리오 설명은 영어를 기본으로 작성합니다.
- 자세한 학습 과정은 작성자의 모국어인 한글 노트로도 보존합니다.
- 각 풀이 문서에서 영문과 한글 문서를 서로 연결합니다.
- 원본 레벨 로직은 그대로 유지하고 설명 주석, 테스트, 재사용 가능한 솔버 컨트랙트를 별도로 관리합니다.
- 실제 블록 진행, 여러 트랜잭션, 외부 상태가 학습에 의미를 더하는 레벨에만 로컬 스크립트를 선택적으로 추가합니다.

### 구버전 컴파일러 호환성

과거 Ethernaut 컨트랙트는 원래 Solidity 버전을 유지합니다. 최신 테스트는 호환되지 않는 소스를 직접 import하지 않고, 별도로 컴파일된 구버전 artifact를 `deployCode()`로 배포한 뒤 최소한의 Solidity 0.8 인터페이스를 통해 호출합니다.

## CI

GitHub Actions는 push와 pull request마다 다음 검사를 실행합니다.

- `forge fmt --check`
- `forge build --sizes`
- `forge test -vvv`

## 사용 기술

- Solidity
- Foundry
- Forge Standard Library
- OpenZeppelin Contracts
- GitHub Actions

## 참고 자료

- [Ethernaut](https://ethernaut.openzeppelin.com/)
- [Ethernaut GitHub 저장소](https://github.com/OpenZeppelin/ethernaut)
- [Foundry 문서](https://getfoundry.sh/)
- [Solidity 문서](https://docs.soliditylang.org/)

## 라이선스 및 출처

Ethernaut 레벨 컨트랙트의 원본 저작권과 라이선스는 OpenZeppelin Ethernaut 프로젝트를 따릅니다. 이 저장소의 테스트, 솔버 컨트랙트, 스크립트, 학습 노트는 교육 목적으로 작성되었습니다.
