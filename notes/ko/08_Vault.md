# 08. Vault

[English](../en/08_Vault.md) | [한국어](08_Vault.md)

## 문제 목표

`private`로 표시된 값을 복구하여 `Vault` 컨트랙트의 잠금을 해제합니다.

## 핵심 개념

- 공개 블록체인 스토리지
- Solidity 스토리지 슬롯
- `private` 가시성 지정자
- `vm.load()`
- 오프체인 스토리지 조회

## 컨트랙트 분석

컨트랙트는 잠금 상태 다음에 private 비밀번호를 저장합니다.

```solidity
bool public locked;
bytes32 private password;
```

Solidity는 선언 순서대로 상태 변수를 스토리지 슬롯에 배치하고 가능한 경우 값을 패킹합니다.

- `locked`는 슬롯 0의 일부를 사용합니다.
- `password`는 완전한 `bytes32`이므로 슬롯 0에 남은 31바이트 공간에 들어갈 수 없습니다.
- 따라서 `password`는 슬롯 1에서 시작합니다.

`private` 지정자는 다른 Solidity 컨트랙트가 변수 이름으로 접근하지 못하게 합니다. 값을 암호화하거나 블록체인 노드와 클라이언트가 실제 스토리지를 읽는 것을 막지는 않습니다.

## 풀이 흐름

Foundry에서는 `vm.load()`로 원시 스토리지 슬롯을 읽을 수 있습니다.

```solidity
bytes32 slot1Data = vm.load(address(target), bytes32(uint256(1)));
```

복구한 값을 접근 제한이 없는 unlock 함수에 전달합니다.

```solidity
vm.prank(player);
target.unlock(slot1Data);
```

```text
잠긴 Vault 배포
        ↓
스토리지 슬롯 1 조회
        ↓
bytes32 비밀번호 복구
        ↓
플레이어가 unlock(복구한 비밀번호) 호출
        ↓
Vault가 같은 값인지 비교
        ↓
locked = false
```

## Foundry 테스트

로컬 테스트는 예상 슬롯과 최종 상태를 함께 검증합니다.

```solidity
assertTrue(target.locked());

bytes32 slot1Data = vm.load(address(target), bytes32(uint256(1)));
assertEq(slot1Data, PASSWORD);

vm.prank(player);
target.unlock(slot1Data);

assertFalse(target.locked());
```

실제 JSON-RPC 네트워크에서는 `cast storage <address> 1`과 같은 RPC 스토리지 조회 명령으로 같은 조사를 수행할 수 있습니다.

## 취약점의 근본 원인

컨트랙트가 접근 가시성을 기밀성으로 오해합니다. Ethereum 컨트랙트 스토리지에 직접 저장한 모든 값은 Solidity에서 `public`, `internal`, `private` 중 무엇으로 표시했는지와 관계없이 네트워크 참여자가 확인할 수 있습니다.

비밀번호와 비밀 키는 private 상태 변수에 넣어도 보호되지 않습니다. 엔트로피가 낮은 비밀번호를 해시하는 것만으로도 충분하지 않습니다. 관찰자가 가능한 값을 오프라인에서 대입해 볼 수 있기 때문입니다.

## 권장 완화 방법

- 평문 비밀 정보나 재사용 가능한 자격 증명을 온체인에 저장하지 않습니다.
- 온체인 값에 대한 지식을 접근 권한으로 사용하지 않습니다.
- 프로토콜에 맞는 서명, 소유권 검사, 허용 목록, 암호학적 커밋 방식을 사용합니다.
- 공개 커밋 값과 공개 시점까지 오프체인에 있어야 하는 값을 분리합니다.
- 업그레이드 가능한 컨트랙트가 정확한 슬롯 위치에 의존한다면 컴파일러의 스토리지 레이아웃을 검토합니다.

## 테스트 실행

```bash
forge test --match-path test/08_Vault.t.sol -vvv
```

스토리지 조회와 잠금 해제의 전체 실행 추적을 확인하려면:

```bash
forge test --match-path test/08_Vault.t.sol -vvvv
```

## 학습 정리

`private`는 어떤 Solidity 코드가 변수 이름으로 접근할 수 있는지를 제어할 뿐 블록체인 데이터를 비밀로 만들지 않습니다. 영구적인 온체인 상태는 모두 공개적으로 관찰 가능하다고 가정해야 합니다.
