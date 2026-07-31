# 09. King

[English](../en/09_King.md) | [한국어](09_King.md)

## 문제 목표

왕의 자리를 차지하고 레벨 소유자가 솔버를 교체하지 못하게 합니다.

## 핵심 개념

- 푸시 방식 ETH 전송
- payable 콜백
- `transfer`
- 외부 호출에 의존하는 상태 전환
- 수신 컨트랙트의 수신 가능 여부

## 컨트랙트 분석

대상은 새로운 왕을 기록하기 전에 현재 왕에게 ETH를 전송합니다.

```solidity
receive() external payable {
    require(msg.value >= prize || msg.sender == owner);
    payable(king).transfer(msg.value);
    king = msg.sender;
    prize = msg.value;
}
```

현재 왕이 ETH를 받을 수 없는 컨트랙트라면 `transfer`가 되돌려집니다. 전체 호출이 원상 복구되므로 이후의 왕과 상금 갱신은 실행되지 않습니다.

## 솔버 컨트랙트

`KingSolver`는 `solve()`를 통해 최초 payable 호출을 수행할 수 있지만 `receive()`와 `fallback()`은 제공하지 않습니다.

```solidity
contract KingSolver {
    function solve(address payable target) external payable {
        (bool success,) = target.call{value: msg.value}("");
        require(success, "Call failed");
    }
}
```

이 구조로 솔버는 왕이 될 수 있지만 대상이 다음 지급금을 솔버에게 전송하는 것은 완료되지 않습니다.

## 풀이 흐름

```text
소유자가 상금 0.1 ETH로 King 배포
        ↓
플레이어가 KingSolver를 통해 1 ETH 전송
        ↓
King이 이전 왕에게 지급하고 KingSolver를 새 왕으로 기록
        ↓
소유자가 2 ETH로 솔버 교체 시도
        ↓
King이 KingSolver에 2 ETH 전송 시도
        ↓
KingSolver에는 payable 콜백이 없음
        ↓
교체 호출이 false를 반환하고 상태는 그대로 유지
```

## Foundry 테스트

테스트는 왕의 자리 획득과 이후 교체 실패를 각각 검증합니다.

```solidity
vm.prank(player);
solver.solve{value: 1 ether}(payable(address(target)));

assertEq(target._king(), address(solver));
assertEq(target.prize(), 1 ether);

vm.prank(owner);
(bool reclaimed,) = address(target).call{value: 2 ether}("");

assertFalse(reclaimed);
assertEq(target._king(), address(solver));
assertEq(target.prize(), 1 ether);
```

저수준 호출의 Boolean 반환값을 직접 확인하므로 예상된 실패가 명확하고 unchecked-call 경고도 남지 않습니다.

## 문제의 근본 원인

이전 상태 전환에서 선택된 주소가 ETH를 정상적으로 받아야 다음 상태 전환이 완료됩니다. 수신 컨트랙트가 전송을 거부하면 남은 상태 갱신도 진행되지 않습니다.

## 권장 개선 방법

- 지급 금액을 기록하고 수신자가 별도로 인출하는 풀 방식을 사용합니다.
- 임의의 수신자가 ETH를 받아야 핵심 상태 전환이 완료되는 구조를 피합니다.
- 외부 지급이 실패할 수 있다면 관련 없는 상태 갱신과 실패 범위를 분리합니다.
- 명시적인 회계를 사용하고 payable 콜백이 있는 수신자와 없는 수신자를 모두 테스트합니다.

## 테스트 실행

```bash
forge test --match-path test/09_King.t.sol -vvv
```

전체 호출 추적을 확인하려면:

```bash
forge test --match-path test/09_King.t.sol -vvvv
```

## 학습 정리

푸시 방식 지급에서는 수신자가 호출자의 상태 전환 완료 여부에 영향을 줄 수 있습니다. 풀 방식 회계는 특정 수신자의 동작이 나머지 프로토콜 진행을 막지 않도록 분리합니다.
