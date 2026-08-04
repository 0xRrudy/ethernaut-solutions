# 14. Gatekeeper Two

[English](../en/14_GatekeeperTwo.md) | [한국어](14_GatekeeperTwo.md)

## 문제 목표

세 개의 게이트를 모두 통과하고 플레이어를 `entrant`로 기록합니다.

## 핵심 개념

- 생성자 실행 시점
- 컨트랙트 코드 크기
- `msg.sender`와 `tx.origin`
- `keccak256`
- XOR 항등식

## Gate One: 호출자와 트랜잭션 시작 주소 분리

```solidity
require(msg.sender != tx.origin);
```

플레이어가 `GatekeeperTwoSolver`를 배포합니다. 솔버 생성자에서 대상을 호출할 때 호출 체인은 다음과 같습니다.

```text
tx.origin  = player
msg.sender = GatekeeperTwoSolver
```

이 구조로 첫 번째 게이트를 통과합니다.

## Gate Two: 생성 중 호출

```solidity
uint256 x;
assembly {
    x := extcodesize(caller())
}
require(x == 0);
```

컨트랙트 생성자가 실행되는 동안 주소는 이미 존재하며 외부 호출도 할 수 있지만 최종 런타임 바이트코드는 아직 해당 주소에 저장되지 않았습니다. 따라서 솔버가 자신의 생성자 안에서 호출할 때 `EXTCODESIZE`는 `0`을 반환합니다.

생성자가 반환되면 런타임 코드가 설치되므로 같은 검사는 더 이상 0이 아닙니다. 대상 호출이 반드시 생성자 안에서 수행되어야 하는 이유입니다.

코드 크기는 신원을 판별하는 안전한 방법이 아닙니다. EOA, 생성 중인 컨트랙트와 일부 생명주기 경계 상태는 모두 관찰 가능한 코드 크기가 0일 수 있습니다.

## Gate Three: XOR 보수 키 계산

대상이 계산한 64비트 해시 조각을 `H`라고 하면 조건은 다음과 같습니다.

```text
H XOR key = 2^64 - 1
```

필요한 키는 `H`의 비트 보수입니다.

```text
key = (2^64 - 1) XOR H
```

`A XOR A = 0`, `A XOR 0 = A` 항등식으로 검증할 수 있습니다.

```text
H XOR ((2^64 - 1) XOR H)
= (H XOR H) XOR (2^64 - 1)
= 0 XOR (2^64 - 1)
= 2^64 - 1
```

대상 내부의 `msg.sender`가 솔버 주소이므로 솔버는 자신의 주소로 `H`를 계산합니다.

```solidity
bytes8 key = bytes8(
    type(uint64).max ^
    uint64(bytes8(keccak256(abi.encodePacked(address(this)))))
);
```

## 풀이 흐름

```text
플레이어가 GatekeeperTwoSolver 배포 시작
        ↓
솔버 생성자가 XOR 보수 키 계산
        ↓
생성자에서 GatekeeperTwo.enter(key) 호출
        ↓
msg.sender와 tx.origin이 다름
        ↓
솔버 런타임 코드가 아직 없어 EXTCODESIZE가 0
        ↓
키와 해시의 XOR 결과가 uint64.max
        ↓
대상이 entrant = player 기록
        ↓
솔버 생성자 종료 후 런타임 코드 설치
```

## Foundry 테스트

```solidity
assertEq(target.entrant(), address(0));

vm.prank(player, player);
solver = new GatekeeperTwoSolver(address(target));

assertEq(target.entrant(), player);
```

## 문제의 근본 원인

대상은 관찰 가능한 코드 크기와 호출 체인 형태를 접근 조건으로 사용합니다. 코드 크기는 생성 과정에서 달라지며 해당 주소가 사람인지, 컨트랙트인지, 권한이 있는지를 증명하지 못합니다.

## 권장 개선 방법

- 컨트랙트 호출을 차단하기 위해 `EXTCODESIZE`나 `address.code.length`를 사용하지 않습니다.
- 명시적 권한, 서명, allowlist 또는 역할 기반 접근 제어를 사용합니다.
- 컨트랙트 지갑과 계정 추상화를 지원할 수 있게 설계합니다.
- 생성자 시점의 호출도 일반적인 외부 상호작용으로 보고 테스트합니다.

## 테스트 실행

```bash
forge test --match-path test/14_GatekeeperTwo.t.sol -vvv
```

## 학습 정리

컨트랙트는 런타임 코드가 존재하기 전에도 다른 컨트랙트를 호출할 수 있습니다. 코드 크기는 주소 생명주기의 한 순간을 나타낼 뿐 신원이나 권한을 증명하지 않습니다.
