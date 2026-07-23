# Ethernaut Foundry 풀이

[English](README.md) | [한국어](README.ko.md)

OpenZeppelin의 [Ethernaut](https://ethernaut.openzeppelin.com/) 워게임을 분석하고 공격 과정을 Foundry 테스트로 재현한 학습 저장소입니다.

각 레벨의 취약한 컨트랙트, 공격 테스트, 풀이 노트를 함께 관리하여 단순 정답뿐 아니라 취약점의 원인, 공격 흐름, 완화 방법까지 기록하는 것을 목표로 합니다.

> [!WARNING]
> 이 저장소의 코드는 스마트 컨트랙트 보안 학습을 위한 것입니다. 명시적인 허가 없이 실제 시스템이나 컨트랙트에 사용하면 안 됩니다.

## 진행 현황

| 번호 | 레벨 | 핵심 주제 | 풀이 | 테스트 |
| :---: | :--- | :--- | :---: | :---: |
| 01 | Fallback | `receive`, 접근 제어, 저수준 `call` | [EN](notes/en/01_Fallback.md) · [KO](notes/ko/01_Fallback.md) | 통과 |

## 저장소 구조

```text
.
├── src/
│   └── 01_Fallback.sol       # Ethernaut 원본 취약 컨트랙트
├── test/
│   └── 01_Fallback.t.sol     # Foundry 공격 재현 테스트
├── notes/
│   ├── en/
│   │   └── 01_Fallback.md    # 영문 취약점 분석
│   └── ko/
│       └── 01_Fallback.md    # 한글 취약점 분석
├── .github/workflows/
│   └── test.yml              # GitHub Actions CI
├── foundry.lock              # 의존성 잠금 파일
└── foundry.toml              # Foundry 설정
```

## 파일 작성 규칙

레벨 번호와 이름을 소스, 테스트, 문서 폴더에서 동일하게 유지합니다.

```text
src/NN_LevelName.sol
test/NN_LevelName.t.sol
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

공격 테스트의 전체 호출 추적:

```bash
forge test --match-test testExploit -vvvv
```

포맷 검사:

```bash
forge fmt --check
```

가스 사용량 확인:

```bash
forge test --gas-report
```

## 문서화 원칙

- README, 소스 주석, 테스트 주석, 포트폴리오 설명은 영어를 기본으로 작성합니다.
- 자세한 학습 과정은 작성자의 모국어인 한글 노트로도 보존합니다.
- 각 풀이 문서에서 영문과 한글 문서를 서로 연결합니다.
- 취약한 레벨의 로직은 그대로 유지하고 설명 주석과 공격 테스트를 별도로 관리합니다.

## CI

GitHub Actions는 push와 pull request마다 다음 검사를 실행합니다.

- `forge fmt --check`
- `forge build --sizes`
- `forge test -vvv`

## 사용 기술

- Solidity
- Foundry
- Forge Standard Library
- GitHub Actions

## 참고 자료

- [Ethernaut](https://ethernaut.openzeppelin.com/)
- [Ethernaut GitHub 저장소](https://github.com/OpenZeppelin/ethernaut)
- [Foundry 문서](https://getfoundry.sh/)
- [Solidity 문서](https://docs.soliditylang.org/)

## 라이선스 및 출처

Ethernaut 레벨 컨트랙트의 원본 저작권과 라이선스는 OpenZeppelin Ethernaut 프로젝트를 따릅니다. 이 저장소의 공격 테스트와 학습 노트는 교육 목적으로 작성되었습니다.
