# 12. Privacy

[English](../en/12_Privacy.md) | [한국어](12_Privacy.md)

## 문제 목표

대상에 저장된 키를 계산해 `locked`를 `false`로 변경합니다.

## 핵심 개념

- EVM 스토리지의 공개성
- Solidity 스토리지 패킹
- 고정 길이 배열
- 명시적 타입 절삭
- Foundry `vm.load`

## 컨트랙트 분석

대상은 세 개의 `bytes32` 원소를 가진 배열을 포함해 여러 값을 `private`로 선언합니다.

```solidity
bytes32[3] private data;

function unlock(bytes16 _key) public {
    require(_key == bytes16(data[2]));
    locked = false;
}
```

`private`는 다른 Solidity 컨트랙트가 자동 생성 getter로 변수에 접근하지 못하게 합니다. 실제 스토리지를 암호화하지는 않습니다. 모든 전체 노드는 트랜잭션을 실행하고 검증하기 위해 컨트랙트 스토리지를 읽을 수 있어야 합니다.

## 스토리지 배치

Solidity는 선언 순서대로 슬롯을 배정하고, 연속된 값들이 32바이트 안에 들어가면 같은 슬롯에 패킹합니다.

| 슬롯 | 저장 내용 |
| :---: | :--- |
| `0` | `locked` (`bool`) |
| `1` | `ID` (`uint256`) |
| `2` | `flattening`, `denomination`, `awkwardness`가 함께 패킹됨 |
| `3` | `data[0]` |
| `4` | `data[1]` |
| `5` | `data[2]` |

고정 길이 배열의 각 `bytes32` 원소는 완전한 슬롯 하나를 차지합니다. 따라서 unlock 키는 슬롯 `5`에 있습니다.

## bytes 타입 변환

`bytes16(data[2])`는 `bytes32` 값의 앞쪽 16바이트를 유지합니다. 테스트도 전체 워드를 읽은 뒤 동일한 변환을 재현해야 합니다.

```solidity
bytes32 storedWord = vm.load(address(target), bytes32(uint256(5)));
bytes16 key = bytes16(storedWord);
```

이는 큰 정수를 작은 정수로 변환할 때 하위 비트를 유지하는 규칙과 구분해야 합니다. 고정 길이 바이트 배열은 바이트 배열 변환 규칙에 따라 정렬되고 절삭됩니다.

## 풀이 흐름

```text
Solidity 선언 순서에 따른 스토리지 배치 계산
        ↓
data[2]가 슬롯 5에 있음을 확인
        ↓
vm.load로 전체 32바이트 워드 읽기
        ↓
unlock()과 동일하게 bytes16으로 변환
        ↓
플레이어가 unlock(key) 호출
        ↓
locked == false 검증
```

## Foundry 테스트

```solidity
bytes16 key = bytes16(
    vm.load(address(target), bytes32(uint256(5)))
);

vm.prank(player);
target.unlock(key);

assertFalse(target.locked());
```

`vm.load`는 로컬 테스트 치트코드이지만 노드나 RPC 스토리지 조회가 읽을 수 있는 것과 같은 공개 블록체인 상태를 보여줍니다.

## 문제의 근본 원인

대상은 `private` 스토리지 값을 비밀처럼 취급합니다. Solidity 가시성은 컨트랙트 수준 접근만 통제하며 블록체인 수준의 기밀성을 제공하지 않습니다.

## 권장 개선 방법

- 공개 블록체인에 평문 비밀이나 재사용 가능한 자격 증명을 저장하지 않습니다.
- 나중에 검증만 필요하다면 커밋값이나 해시를 저장합니다.
- 보호 기간 이후 값을 공개할 수 있다면 commit-reveal 구조를 사용합니다.
- 실제 기밀 정보는 오프체인에 보관하거나 목적에 맞는 암호 프로토콜을 사용합니다.
- 패킹이 슬롯 위치에 영향을 주므로 스토리지 배치 가정을 문서화하고 업그레이드를 신중히 테스트합니다.

## 테스트 실행

```bash
forge test --match-path test/12_Privacy.t.sol -vvv
```

## 학습 정리

`private`는 “Solidity getter가 없음”을 뜻할 뿐 “관찰자에게 숨겨짐”을 뜻하지 않습니다. 컨트랙트 스토리지는 공개 데이터이며 패킹 규칙은 그 데이터의 위치만 바꿉니다.
