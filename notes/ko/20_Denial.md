# 20. Denial

[English](../en/20_Denial.md) | [한국어](20_Denial.md)

## 문제 목표

트랜잭션이 100만 이하의 가스를 제공할 때 `withdraw()`가 완료되지 않도록 하는 출금 partner를 설정합니다.

## 핵심 개념

- 제한 없는 가스 전달
- EIP-150의 63/64 가스 규칙
- 저수준 호출의 가스 소진 동작
- 푸시 방식 지급
- 핵심 상태 전환의 가용성

## 컨트랙트 분석

`withdraw()`는 컨트랙트 잔액의 1%를 계산하고 임의의 partner를 호출한 다음에야 owner 지급과 회계 갱신을 수행합니다.

```solidity
function withdraw() public {
    uint256 amountToSend = address(this).balance / 100;

    partner.call{value: amountToSend}("");
    payable(owner).transfer(amountToSend);

    timeLastWithdrawn = block.timestamp;
    withdrawPartnerBalances[partner] += amountToSend;
}
```

partner 주소에는 제한이 없어 어떤 컨트랙트도 지정할 수 있습니다. 저수준 호출은 가스 한도를 지정하지 않으므로 해당 시점에 남은 가스의 거의 전부를 전달합니다.

## EIP-150 가스 전달

EIP-150에 따라 중첩 호출은 호출자에게 남은 가스의 최대 63/64만 받을 수 있습니다. 약 1/64은 호출자 프레임에 남습니다.

```text
partner에 전달되는 가스 ≈ 남은 가스 × 63 / 64
Denial에 남는 가스       ≈ 남은 가스 ×  1 / 64
```

이 규칙은 피호출자가 호출자의 모든 가스 단위를 가져가는 상황을 제한합니다. 하지만 호출 이후의 비싼 작업을 끝내기에 충분한 가스가 남는다고 보장하지는 않습니다.

100만 가스로 출금을 호출한 실행 추적에서는 partner가 약 975,000 가스를 받습니다. partner 호출 이후 `Denial`에는 작은 비율의 가스만 남습니다.

## revert와 가스 소진의 차이

대상 주석은 partner가 revert하더라도 저수준 호출이 `false`를 반환하고 실행이 계속되므로 괜찮다고 가정합니다. 콜백이 즉시 revert하면 사용하지 않은 가스가 호출자에게 돌아오기 때문에 이 설명이 맞습니다.

솔버는 즉시 revert하지 않고 전달받은 가스가 모두 소진될 때까지 계속 실행합니다.

```solidity
receive() external payable {
    while (true) {}
}
```

중첩 호출은 여전히 실패로 반환되지만 사용하지 않은 가스가 거의 없습니다. 호출자에는 EIP-150으로 보존된 일부 가스만 남습니다. 이 가스로는 이후 value transfer와 스토리지 쓰기를 모두 완료할 수 없습니다.

결국 바깥 `withdraw()`도 가스 부족으로 실패합니다. 전체 트랜잭션이 되돌려지므로 앞서 partner에게 보냈던 ETH도 원상 복구되고 대상 잔액은 그대로 유지됩니다.

## 풀이 흐름

```text
대상이 1 ETH 보유
        ↓
DenialSolver를 출금 partner로 설정
        ↓
플레이어가 1,000,000 가스로 withdraw() 호출
        ↓
Denial이 남은 가스의 약 63/64 전달
        ↓
솔버 콜백이 전달된 가스를 모두 소진할 때까지 반복
        ↓
partner 저수준 호출이 아주 적은 가스만 남긴 채 false 반환
        ↓
Denial이 owner 지급과 회계 갱신을 완료하지 못함
        ↓
바깥 호출이 실패하고 모든 value transfer가 원상 복구됨
```

## Foundry 테스트

테스트는 예상된 실패가 테스트 자체를 종료하게 두지 않고 바깥 호출의 결과를 직접 받습니다.

```solidity
address owner = target.owner();
uint256 ownerBalanceBefore = owner.balance;

assertEq(target.partner(), address(solver));
assertEq(target.contractBalance(), 1 ether);

vm.prank(player);
(bool success,) = address(target).call{gas: 1_000_000}(
    abi.encodeWithSelector(Denial.withdraw.selector)
);

assertFalse(success);
assertEq(target.contractBalance(), 1 ether);
assertEq(owner.balance, ownerBalanceBefore);
```

이 assertion들은 호출 실패뿐 아니라 대상이 자금을 그대로 보유하고 owner가 아무것도 받지 못했다는 사실도 검증합니다.

## 문제의 근본 원인

핵심 상태 전환이 외부 입력으로 선택된 주소에 제한 없이 호출하고, owner 지급과 회계 갱신을 끝내기 전에 거의 모든 가스를 전달합니다. 그 결과 partner가 함수 완료에 필요한 실행 자원이 남을지를 결정하게 됩니다.

## 권장 개선 방법

- 각 수신자가 독립적으로 출금하는 풀 방식 지급을 사용합니다.
- 한 수신자의 콜백이 다른 수신자 지급의 선행 조건이 되지 않게 합니다.
- 신뢰할 수 없는 콜백에는 의도적인 가스 한도를 적용합니다.
- partner 지급 실패는 결합된 푸시 지급을 계속하는 대신 명시적인 회계 상태로 처리합니다.
- 의도한 불변조건이 허용한다면 외부 상호작용 전에 중요한 상태를 갱신합니다.
- 정상 반환, 즉시 revert, 전체 가스 소진 콜백을 모두 테스트합니다.
- 저수준 호출의 Boolean 결과를 확인하더라도 피호출자가 이미 소비한 가스는 되돌아오지 않는다는 점을 기억합니다.

## 테스트 실행

```bash
forge test --match-path test/20_Denial.t.sol -vvv
```

전체 가스 실행 추적:

```bash
forge test --match-path test/20_Denial.t.sol -vvvv
```

## 학습 정리

실패한 저수준 호출을 무시하면 제어 흐름은 이어질 수 있지만 가스까지 보존되지는 않습니다. 남은 가스의 거의 전부를 받은 신뢰할 수 없는 콜백은 그 뒤에 배치된 모든 상태 전환의 완료를 막을 수 있습니다.
