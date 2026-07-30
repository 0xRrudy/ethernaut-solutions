# 07. Force

[English](../en/07_Force.md) | [한국어](07_Force.md)

## 문제 목표

비어 있는 `Force` 컨트랙트가 0보다 많은 ETH 잔액을 보유하게 합니다.

## 핵심 개념

- 강제 ETH 전송
- `selfdestruct`
- 컨트랙트 잔액과 payable 함수의 차이
- 잘못된 잔액 불변 조건
- Cancun 이후의 `selfdestruct` 동작

## 컨트랙트 분석

대상에는 payable 생성자, receive, fallback, 일반 함수가 모두 없습니다.

```solidity
contract Force {}
```

이 컨트랙트는 payable 진입점을 제공하지 않으므로 직접 ETH를 전송하면 되돌려집니다. 하지만 컨트랙트가 가능한 모든 잔액 증가를 거부할 수 있는 것은 아닙니다.

EVM의 `selfdestruct` 연산은 실행 중인 컨트랙트의 전체 ETH 잔액을 수익자에게 전송하면서 수익자 컨트랙트의 함수를 호출하지 않습니다. 따라서 대상은 이 전송을 수락하거나 거부할 기회가 없고 코드도 실행하지 않습니다.

## 솔버 컨트랙트

도우미 컨트랙트가 먼저 receive 함수로 ETH를 받은 뒤 `selfdestruct`의 수익자로 `Force`를 지정합니다.

```solidity
contract ForceSolver {
    function solve(address payable target) external {
        selfdestruct(target);
    }

    receive() external payable {}
}
```

Cancun 하드포크 이후에는 기존 컨트랙트에서 `selfdestruct`를 호출해도 일반적으로 코드와 스토리지가 삭제되지 않습니다. 하지만 ETH 잔액 전송은 계속 수행되므로 이 레벨이 보여주는 강제 잔액 전송 특성은 여전히 유효합니다.

## 풀이 흐름

```text
잔액 0으로 Force 배포
        ↓
ForceSolver 배포
        ↓
플레이어가 ForceSolver.receive()에 0.1 ETH 전송
        ↓
ForceSolver 잔액 = 0.1 ETH
        ↓
ForceSolver.solve(Force) 호출
        ↓
selfdestruct가 Force 함수를 호출하지 않고 전체 잔액 전송
        ↓
Force 잔액 = 0.1 ETH
```

## Foundry 테스트

테스트는 초기 상태와 강제로 전송된 정확한 잔액을 모두 검증합니다.

```solidity
assertEq(address(target).balance, 0);

vm.startPrank(player);
(bool funded,) = payable(solver).call{value: 0.1 ether}("");
assertTrue(funded);

solver.solve(payable(address(target)));
vm.stopPrank();

assertEq(address(target).balance, 0.1 ether);
```

`address(target).balance`는 `Force`의 함수를 호출하는 것이 아니라 해당 계정의 ETH 잔액을 직접 읽습니다.

## 취약점의 근본 원인

이 문제는 컨트랙트의 잔액이 payable 함수를 통해서만 변경될 수 있다는 잘못된 불변 조건을 보여줍니다. EVM 수준의 잔액 변경은 수신자 코드를 실행하지 않고도 발생할 수 있습니다.

프로토콜을 설계할 때는 `selfdestruct`뿐 아니라 검증자 보상이나 결정적 배포 주소에 미리 전송된 ETH처럼 함수 호출 없이 잔액이 생기는 상황도 고려해야 합니다.

## 권장 완화 방법

- `address(this).balance == expectedAmount`를 중요한 불변 조건으로 사용하지 않습니다.
- 원시 계정 잔액과 별도로 내부 회계를 기록합니다.
- 필요한 경우 예기치 않은 ETH를 허용할 수 있는 비교 방식을 사용합니다.
- payable 함수가 없다는 이유로 잔액이 항상 0이라고 가정하지 않습니다.
- 인출과 정산 로직은 전체 원시 잔액이 아니라 기록된 채무를 기준으로 설계합니다.

## 테스트 실행

```bash
forge test --match-path test/07_Force.t.sol -vvv
```

강제 전송의 전체 실행 추적을 확인하려면:

```bash
forge test --match-path test/07_Force.t.sol -vvvv
```

## 학습 정리

스마트 컨트랙트는 어떤 호출을 수락할지는 제어할 수 있지만 자신의 주소가 ETH를 받는 모든 경로를 통제할 수는 없습니다. 보안상 중요한 회계는 원시 잔액이 알려진 함수로만 변경된다는 가정에 의존하면 안 됩니다.
