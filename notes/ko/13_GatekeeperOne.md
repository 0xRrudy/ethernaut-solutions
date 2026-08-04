# 13. Gatekeeper One

[English](../en/13_GatekeeperOne.md) | [한국어](13_GatekeeperOne.md)

## 문제 목표

세 개의 게이트를 모두 통과하고 플레이어를 `entrant`로 기록합니다.

## 핵심 개념

- `msg.sender`와 `tx.origin`
- 남은 가스 조건
- 비트 마스크와 정수 절삭
- 가스를 명시한 저수준 호출
- 제한된 나머지 범위 탐색

## Gate One: 컨트랙트를 경유한 호출

```solidity
require(msg.sender != tx.origin);
```

플레이어가 `GatekeeperOneSolver`를 호출하고 솔버가 다시 대상을 호출합니다. 대상 내부 값은 다음과 같습니다.

```text
tx.origin  = player
msg.sender = GatekeeperOneSolver
```

두 주소가 다르므로 첫 번째 게이트를 통과합니다.

## Gate Two: 가스 나머지 맞추기

```solidity
require(gasleft() % 8191 == 0);
```

modifier 내부의 정확한 `gasleft()` 값은 `call{gas: ...}`에 지정한 숫자와 같지 않습니다. 호출 준비, calldata 처리, 컴파일된 코드와 앞선 명령들이 검사 전에 가스를 소비합니다.

솔버는 특정 환경의 오프셋 하나를 하드코딩하지 않고 모듈러 한 주기에 해당하는 모든 나머지를 시도합니다.

```solidity
for (uint256 i = 0; i < 8191; i++) {
    uint256 gasToUse = (8191 * 10) + i;
    (bool success,) = target.call{gas: gasToUse}(
        abi.encodeWithSignature("enter(bytes8)", key)
    );

    if (success) return true;
}
```

저수준 호출은 각 실패를 `success == false`로 바꾸므로 반복문이 다음 후보를 계속 확인할 수 있습니다.

## Gate Three: 키 구성

키를 `uint64`로 해석한 값을 `K`라고 하면 조건은 다음과 같습니다.

```text
uint32(K) == uint16(K)
uint32(K) != uint64(K)
uint32(K) == uint16(uint160(tx.origin))
```

이를 비트 배치로 바꾸면 다음과 같습니다.

```text
비트  0–15: tx.origin 주소의 하위 16비트
비트 16–31: 모두 0
비트 32–63: 하나 이상의 비트가 1
```

테스트는 이 조건을 그대로 구성합니다.

```solidity
uint64 keyValue = (uint64(1) << 32) | uint16(uint160(player));
bytes8 key = bytes8(keyValue);
```

왼쪽으로 32비트 이동한 `1`은 하위 32비트 조건을 바꾸지 않으면서 상위 32비트를 0이 아니게 만듭니다.

## 풀이 흐름

```text
플레이어 주소 하위 16비트로 bytes8 키 구성
        ↓
플레이어가 솔버 호출
        ↓
솔버 경유로 msg.sender != tx.origin 구성
        ↓
솔버가 8191을 법으로 하는 가스 오프셋 탐색
        ↓
한 후보가 gasleft() % 8191 == 0 만족
        ↓
키가 모든 정수 절삭 조건 통과
        ↓
대상이 entrant = player 기록
```

## Foundry 테스트

```solidity
vm.prank(player, player);
bool result = solver.solve(address(target), key);

assertTrue(result);
assertEq(target.entrant(), player);
```

인수가 두 개인 `prank`는 플레이어의 바깥 호출에 대해 `msg.sender`와 `tx.origin`을 모두 설정합니다.

## 문제의 근본 원인

컨트랙트는 호출 체인 형태, 불안정한 가스 나머지와 주소 일부 비트를 자격 증명처럼 사용합니다. 어느 값도 인증이나 안정적인 권한 경계를 제공하지 않습니다.

## 권장 개선 방법

- 명시적인 역할 또는 서명 기반 인증을 사용합니다.
- 접근 제어에 `tx.origin`을 사용하지 않습니다.
- `gasleft()`를 신원이나 자격 검사로 사용하지 않습니다.
- 잘린 주소 일부에 인증을 의존하지 않습니다.
- 정확한 가스 동작이 운영상 중요하다면 컴파일러와 EVM 버전별로 테스트하되 보안 수단으로 취급하지 않습니다.

## 테스트 실행

```bash
forge test --match-path test/13_GatekeeperOne.t.sol -vvv
```

## 학습 정리

가스 값과 주소 일부 비트는 퍼즐 조건을 만들 수 있지만 신뢰할 수 있는 권한 검사를 만들지는 못합니다. 보안 결정은 명시적인 신원과 검증 가능한 권한에 기반해야 합니다.
