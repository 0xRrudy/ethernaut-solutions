# 05. Token

[English](../en/05_Token.md) | [한국어](05_Token.md)

## 문제 목표

플레이어에게 처음 지급된 20개보다 많은 토큰을 보유합니다.

## 핵심 개념

- 부호 없는 정수의 언더플로
- Solidity 0.6의 검사 없는 산술 연산
- 모듈러 연산
- 상태 변경 전 검증
- `deployCode()`를 이용한 다중 버전 테스트

## 컨트랙트 분석

`transfer` 함수는 호출자의 잔액을 초과하는 전송을 막으려고 합니다.

```solidity
function transfer(address _to, uint256 _value) public returns (bool) {
    require(balances[msg.sender] - _value >= 0);
    balances[msg.sender] -= _value;
    balances[_to] += _value;
    return true;
}
```

하지만 이 검사는 의도대로 동작하지 않습니다. `balances[msg.sender]`와 `_value`가 모두 `uint256`이므로 뺄셈 결과도 `uint256`입니다. 부호 없는 정수는 음수를 표현할 수 없으므로 언제나 0 이상입니다.

Solidity 0.6에서는 오버플로나 언더플로가 발생해도 자동으로 되돌려지지 않습니다. 대신 값이 `2^256`을 기준으로 순환합니다.

## 언더플로 계산

플레이어가 20개를 가진 상태에서 21개를 전송합니다.

```text
20 - 21
= -1 mod 2^256
= 2^256 - 1
= 115792089237316195423570985008687907853269984665640564039457584007913129639935
```

`require` 내부에서도 같은 순환 결과를 계산합니다. 이 값은 매우 큰 양수 형태의 `uint256`이므로 조건을 통과합니다. 이어지는 잔액 차감도 같은 방식으로 순환하여 플레이어의 잔액에 `uint256` 최댓값을 저장합니다.

토큰을 받는 주소는 플레이어와 달라야 합니다. 플레이어 자신에게 전송하면 같은 매핑 값에서 토큰을 뺀 직후 다시 더하므로 원래 잔액으로 돌아갑니다.

## 풀이 흐름

```text
플레이어 잔액 = 20
        ↓
플레이어가 별도 수신자에게 토큰 21개 전송
        ↓
require 표현식이 순환된 uint256 값을 계산
        ↓
송신자 잔액 차감이 2^256 - 1로 순환
        ↓
수신자 잔액 = 21
플레이어 잔액 = type(uint256).max
```

플레이어가 `transfer()`를 직접 호출하면 되므로 중간 솔버 컨트랙트는 필요하지 않습니다.

## Foundry 테스트

취약한 대상은 Solidity 0.6을 사용하지만 현재 Forge Standard Library에는 Solidity 0.8이 필요합니다. 두 소스를 하나의 컴파일 단위에서 직접 import하면 pragma 버전이 충돌합니다.

따라서 테스트에는 대상의 ABI만 인터페이스로 선언합니다.

```solidity
interface IToken {
    function transfer(address to, uint256 value) external returns (bool);
    function balanceOf(address account) external view returns (uint256);
}
```

Forge는 구버전 소스를 별도로 컴파일합니다. `deployCode()`는 해당 생성 바이트코드를 불러온 후 ABI로 인코딩한 생성자 인수를 덧붙여 배포합니다.

```solidity
target = IToken(
    deployCode("05_Token.sol:Token", abi.encode(uint256(100)))
);
```

`deployCode()`가 테스트 컨트랙트에서 대상을 생성하므로 초기 공급량은 테스트 컨트랙트가 받습니다. `setUp()`에서 테스트 컨트랙트가 플레이어에게 토큰 20개를 전송하여 레벨의 초기 상태를 재현합니다.

풀이 테스트에서는 다음 호출에 한해 플레이어 주소를 사용합니다.

```solidity
vm.prank(player);
bool transferred = target.transfer(receiver, 21);

assertTrue(transferred);
assertEq(target.balanceOf(receiver), 21);
assertEq(target.balanceOf(player), type(uint256).max);
```

## 테스트 흐름

```text
초기 공급량 100으로 Solidity 0.6 Token artifact 배포
        ↓
테스트 컨트랙트가 플레이어에게 토큰 20개 전송
        ↓
다음 호출의 msg.sender를 플레이어로 설정
        ↓
별도 수신자에게 토큰 21개 전송
        ↓
수신자가 토큰 21개를 보유하는지 검증
        ↓
플레이어 잔액이 type(uint256).max인지 검증
```

## 취약점의 근본 원인

컨트랙트는 뺄셈 전에 피연산자를 확인하지 않고, 안전하지 않은 뺄셈의 결과를 검사합니다. 산술 연산이 자동으로 검사되지 않는 환경에서는 비교가 실행될 때 이미 값이 언더플로되어 순환한 상태입니다.

다음 조건은:

```solidity
require(balances[msg.sender] - _value >= 0);
```

송신자의 현재 잔액이 요청한 전송량보다 크거나 같아야 한다는 실제 불변 조건을 직접 표현해야 합니다.

## 권장 완화 방법

- 뺄셈 전에 `balances[msg.sender] >= _value`를 검사합니다.
- 산술 오버플로와 언더플로를 기본적으로 되돌리는 Solidity 0.8 이상을 사용합니다.
- 구버전 컴파일러에서는 OpenZeppelin `SafeMath`와 같은 검사된 산술 라이브러리를 사용합니다.
- 이미 계산된 위험한 결과가 아니라 연산 전 피연산자를 검증합니다.
- 잔액이 0인 경우, 잔액 전체를 전송하는 경우, 잔액보다 1개 많이 전송하는 경우를 테스트합니다.

Solidity 0.8에서는 원본 뺄셈이 Boolean 비교를 완료하기 전에 산술 패닉으로 되돌려집니다. 그래도 명시적인 잔액 검사는 의도한 규칙을 분명히 표현하고 의미 있는 오류를 제공할 수 있으므로 권장됩니다.

## 테스트 실행

```bash
forge test --match-path test/05_Token.t.sol -vvv
```

전체 호출 추적을 확인하려면:

```bash
forge test --match-path test/05_Token.t.sol -vvvv
```

## 학습 정리

부호 없는 값이 0 이상인지 확인하는 것은 유효한 잔액 검사가 아닙니다. 뺄셈 전에 잔액이 전송량 이상인지 검증해야 하며, Solidity 컴파일러 버전에 따라 산술 연산의 동작이 달라진다는 점을 기억해야 합니다.
