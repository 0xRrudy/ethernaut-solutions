# 17. Recovery

[English](../en/17_Recovery.md) | [한국어](17_Recovery.md)

## 문제 목표

생성된 `SimpleToken` 컨트랙트 주소를 다시 계산하고 해당 주소의 ETH 잔액을 플레이어에게 돌려보냅니다.

## 핵심 개념

- 결정론적인 `CREATE` 주소
- 컨트랙트 계정 nonce
- Recursive Length Prefix(RLP) 인코딩
- `keccak256` 결과에서 주소 절삭
- 최신 `SELFDESTRUCT` 동작

## 컨트랙트 분석

`Recovery.generateToken()`은 새로운 컨트랙트를 만들지만 주소를 저장하거나 반환하지 않습니다.

```solidity
function generateToken(
    string memory _name,
    uint256 _initialSupply
) public {
    new SimpleToken(_name, msg.sender, _initialSupply);
}
```

하지만 이 주소는 EVM에서 무작위로 정해지거나 실제로 사라진 것이 아닙니다. `CREATE` opcode로 생성한 주소는 생성자 주소와 생성자의 nonce로 결정됩니다.

## CREATE 주소 공식

`CREATE` 주소 공식은 다음과 같습니다.

```text
createdAddress = last20bytes(
    keccak256(RLP([creatorAddress, creatorNonce]))
)
```

`Recovery`는 첫 번째 자식 컨트랙트를 nonce `1`로 생성합니다. 20바이트 생성자 주소와 한 바이트 값 `1`을 RLP로 인코딩하면 다음 바이트가 됩니다.

```text
0xd6 || 0x94 || creatorAddress || 0x01
```

| 바이트 | 의미 |
| :--- | :--- |
| `0xd6` | 22바이트 payload를 가진 RLP 목록 prefix |
| `0x94` | 20바이트 주소를 나타내는 RLP 문자열 prefix |
| `creatorAddress` | `Recovery` 컨트랙트 주소 |
| `0x01` | 첫 번째 `CREATE`에 사용된 생성자 nonce |

테스트는 이 바이트를 해시한 뒤 하위 20바이트를 유지합니다.

```solidity
bytes32 addressHash = keccak256(
    abi.encodePacked(
        bytes1(0xd6),
        bytes1(0x94),
        creator,
        bytes1(0x01)
    )
);

address tokenAddress = address(uint160(uint256(addressHash)));
```

nonce가 여러 바이트를 필요로 하면 RLP 인코딩도 달라집니다. 따라서 이 짧은 식은 첫 번째 자식 컨트랙트에 맞춘 계산입니다.

## 풀이 흐름

```text
Recovery가 CREATE nonce 1로 첫 SimpleToken 생성
        ↓
RLP([Recovery 주소, 1]) 재구성
        ↓
인코딩된 바이트를 keccak256으로 해시
        ↓
하위 20바이트를 SimpleToken 주소로 사용
        ↓
해당 주소에 0.001 ETH가 있음을 확인
        ↓
SimpleToken.destroy(player) 호출
        ↓
토큰 주소 잔액 0과 플레이어의 ETH 수령 검증
```

## Foundry 테스트

수동 계산 결과를 Foundry 주소 계산 치트코드와도 비교합니다.

```solidity
assertEq(
    tokenAddress,
    vm.computeCreateAddress(address(target), 1)
);
assertEq(tokenAddress.balance, 0.001 ether);

uint256 playerBalanceBefore = player.balance;

vm.prank(player);
SimpleToken(payable(tokenAddress)).destroy(payable(player));

assertEq(tokenAddress.balance, 0);
assertEq(player.balance, playerBalanceBefore + 0.001 ether);
```

## SELFDESTRUCT 참고

최신 EVM 규칙에서는 `SELFDESTRUCT`가 코드와 스토리지를 제거하는 조건이 제한됩니다. 하지만 남은 ETH를 지정한 수신자에게 보내는 효과는 유지됩니다. 이 레벨의 완료 조건은 영구적인 코드 삭제가 아니라 ETH 회수입니다.

## 문제의 근본 원인

애플리케이션이 생성된 주소를 보관하거나 이벤트로 남기지 않지만 결정론적인 컨트랙트 생성 규칙 때문에 공개 상태와 생성 순서로 주소를 복구할 수 있습니다.

## 권장 개선 방법

- 팩토리 함수에서 생성된 주소를 반환합니다.
- 생성 주소와 관련 메타데이터를 이벤트로 기록합니다.
- 애플리케이션이 나중에 찾아야 한다면 자식 컨트랙트 주소를 저장합니다.
- 전체 잔액을 이동하는 생명주기 함수에는 접근 제어를 적용합니다.
- 과거 `SELFDESTRUCT`의 코드 삭제 동작을 전제로 최신 시스템을 설계하지 않습니다.

## 테스트 실행

```bash
forge test --match-path test/17_Recovery.t.sol -vvv
```

## 학습 정리

`CREATE`로 생성되는 컨트랙트 주소는 결정론적입니다. 저장된 참조가 없어도 생성자 주소와 nonce를 알면 첫 번째 자식 주소를 다시 계산할 수 있습니다.
