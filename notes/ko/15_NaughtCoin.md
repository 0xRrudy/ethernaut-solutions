# 15. Naught Coin

[English](../en/15_NaughtCoin.md) | [한국어](15_NaughtCoin.md)

## 문제 목표

10년의 전송 잠금 기간이 끝나기 전에 플레이어의 전체 토큰 잔액을 이동합니다.

## 핵심 개념

- ERC-20 allowance
- `transfer`와 `transferFrom`
- 상속된 기능
- 공통 내부 전송 경로
- 불변조건 수준의 제한

## 컨트랙트 분석

대상은 `transfer()`만 override하고 최초 플레이어가 호출할 때 시간 잠금 modifier를 적용합니다.

```solidity
function transfer(
    address _to,
    uint256 _value
) public override lockTokens returns (bool) {
    super.transfer(_to, _value);
}
```

상속한 ERC-20 컨트랙트에는 다음 두 함수도 그대로 공개되어 있습니다.

```text
approve(spender, amount)
transferFrom(owner, recipient, amount)
```

`approve()`는 spender에게 사용 권한을 부여합니다. spender는 `transferFrom()`으로 owner의 잔액을 이동할 수 있습니다. 대상은 `transferFrom()`을 override하지 않았고 공통 내부 전송 훅에서도 잠금을 검사하지 않으므로 이 경로에서는 `lockTokens`가 실행되지 않습니다.

## ERC-20 호출 경로

두 경로는 서로 다른 외부 진입점을 사용합니다.

```text
직접 경로
player → transfer(recipient, amount) → lockTokens → timeLock 이전이라 revert

allowance 경로
player → approve(spender, amount)
spender → transferFrom(player, spender, amount) → 상속된 ERC-20 로직 → 성공
```

의도한 정책은 “기한 전에는 플레이어 토큰이 이동할 수 없음”이지만 구현은 “플레이어가 이 함수 하나를 호출할 수 없음”만 강제합니다. 상태 전환에 대한 정책은 해당 전환을 만들 수 있는 모든 함수에 적용되어야 합니다.

## 풀이 흐름

```text
플레이어의 전체 ERC-20 잔액 조회
        ↓
직접 transfer가 현재 잠겨 있음을 확인
        ↓
플레이어가 별도 spender에게 전체 잔액 allowance 부여
        ↓
spender가 transferFrom(player, spender, 전체 잔액) 호출
        ↓
상속된 ERC-20 회계 로직이 토큰 이동
        ↓
플레이어 잔액이 0이 됨
```

## Foundry 테스트

```solidity
uint256 amount = target.balanceOf(player);

vm.startPrank(player);
vm.expectRevert();
target.transfer(spender, 1);
assertTrue(target.approve(spender, amount));
vm.stopPrank();

vm.prank(spender);
assertTrue(target.transferFrom(player, spender, amount));

assertEq(target.balanceOf(player), 0);
assertEq(target.balanceOf(spender), amount);
assertEq(target.allowance(player, spender), 0);
```

직접 전송 검증은 시간 잠금이 실제로 활성화되어 있음을 보여주고, 나머지 assertion은 다른 ERC-20 경로로 완료 조건을 만족했음을 증명합니다.

## 문제의 근본 원인

제한이 공통 토큰 이동 로직이 아니라 하나의 공개 wrapper에만 붙어 있습니다. 상속된 다른 함수들은 의도한 정책을 적용하지 않고 같은 잔액을 바꿀 수 있습니다.

## 권장 개선 방법

- `transfer()`와 `transferFrom()`이 모두 사용하는 공통 내부 훅에서 전송 제한을 강제합니다.
- OpenZeppelin Contracts 4.x에서는 적절한 전송 훅 또는 공통 내부 전송 경로를 override합니다.
- 토큰 표준을 확장할 때 상속받은 모든 public 함수를 검토합니다.
- 잔액을 이동할 수 있는 모든 진입점을 대상으로 불변조건 테스트를 작성합니다.
- ERC-20 wrapper 함수는 상속 함수의 Boolean 결과를 반환해 인터페이스 의미를 유지합니다.

## 테스트 실행

```bash
forge test --match-path test/15_NaughtCoin.t.sol -vvv
```

## 학습 정리

함수 하나의 검사는 상태 전체의 정책을 자동으로 보장하지 않습니다. ERC-20처럼 조합 가능한 표준에서는 보호하려는 상태 전환으로 이어지는 모든 상속 경로를 확인해야 합니다.
