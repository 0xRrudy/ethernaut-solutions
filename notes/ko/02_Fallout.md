# 02. Fallout

[English](../en/02_Fallout.md) | [한국어](02_Fallout.md)

## 문제 목표

`Fallout` 컨트랙트의 소유권을 가져옵니다.

## 핵심 개념

- 생성자 문법과 과거의 이름 기반 생성자 방식
- 보호되지 않은 초기화
- 권한 로직에 포함된 함수 이름 오타
- `msg.sender` 기반 소유권
- 최신 Foundry를 이용한 구버전 Solidity artifact 테스트
- ABI 호환 인터페이스와 `deployCode()`

## 컨트랙트 분석

### 과거 Solidity의 생성자 문법

Solidity 0.4.22 이전에는 전용 `constructor` 키워드를 사용하지 않았습니다. 대신 컨트랙트 이름과 정확히 같은 이름의 함수를 작성하면 해당 함수가 생성자로 처리되어 배포 시 한 번만 실행되었습니다.

```solidity
contract Fallout {
    function Fallout() public {
        owner = msg.sender;
    }
}
```

위 과거 문법에서는 `Fallout()`과 `contract Fallout`의 이름이 정확히 같기 때문에 해당 함수가 생성자 역할을 합니다.

하지만 이 방식은 생성자 여부가 대소문자까지 정확히 일치하는 함수 이름에 의존한다는 문제가 있습니다. 컨트랙트 이름을 변경하면서 함수 이름을 바꾸지 않거나 작은 오타를 입력하면, 생성자로 의도한 함수가 일반 공개 함수로 바뀔 수 있습니다.

Solidity 0.4.22에서는 초기화 역할을 명확히 구분하기 위해 `constructor` 키워드가 도입되었습니다. 기존의 이름 기반 생성자 문법은 deprecated 되었고 Solidity 0.5.0부터 사용할 수 없게 되었습니다.

현재 생성자 문법은 컨트랙트 이름과 초기화 역할을 분리합니다.

```solidity
contract Fallout {
    constructor() {
        owner = msg.sender;
    }
}
```

### 왜 함수 이름이 `Fal1out`인가?

문제의 함수 이름은 `Fallout`과 거의 같아 보이지만, 소문자 `l` 하나가 숫자 `1`로 바뀌어 있습니다.

```text
컨트랙트: Fallout
함수:     Fal1out
               ↑ 숫자 1
```

과거 이름 기반 생성자 문법에서 의도한 생성자 이름은 `Fallout()`이어야 합니다. `Fal1out()`은 컨트랙트 이름과 정확히 일치하지 않으므로 구버전 컴파일러에서도 생성자가 아니라 일반 함수로 처리됩니다.

현재 재현 코드가 사용하는 Solidity 0.6에서는 이름 기반 생성자 문법 자체가 더 이상 지원되지 않습니다. 따라서 오타 여부와 별개로 `constructor` 키워드를 사용해야만 생성자가 됩니다. 이 레벨에는 과거에 실제로 발생할 수 있었던 취약점을 설명하기 위해 오타가 포함된 함수가 그대로 남아 있습니다.

### 취약한 초기화 함수

컨트랙트에는 생성자로 표시된 다음 함수가 있습니다.

```solidity
/* constructor */
function Fal1out() public payable {
    owner = msg.sender;
    allocations[owner] = msg.value;
}
```

하지만 이 함수는 생성자가 아닙니다. 배포 후에도 누구나 호출할 수 있는 일반적인 `public payable` 함수입니다.

어떤 주소든 `Fal1out()`을 호출하면 `owner`를 자신의 주소로 덮어쓸 수 있습니다. 일회성 초기화 검사나 접근 제어도 없으므로 이 함수는 반복해서 호출할 수 있습니다.

## 공격 흐름

```text
Fallout 컨트랙트 배포
        ↓
생성자로 의도한 함수가 public 상태로 남음
        ↓
공격자가 1 wei와 함께 Fal1out() 호출
        ↓
owner = attacker
        ↓
소유권 탈취 확인
```

## Foundry 공격 코드

```solidity
function testExploit() public {
    vm.startPrank(attacker);

    falloutContract.Fal1out{value: 1 wei}();

    assertEq(falloutContract.owner(), attacker);

    vm.stopPrank();
}
```

소유자가 되는 데 ETH 전송은 필수가 아니지만, `1 wei`를 함께 보내면 호출자의 allocation도 기록된다는 사실을 확인할 수 있습니다.

## Solidity 0.6 컨트랙트를 최신 forge-std로 테스트하는 방법

취약한 컨트랙트는 Solidity 0.6을 사용하지만 설치된 forge-std는 Solidity 0.8.13 이상을 요구합니다. 두 소스를 하나의 테스트 컴파일 단위에서 직접 import하면 호환되는 컴파일러 버전이 없어 오류가 발생합니다.

따라서 테스트에는 필요한 함수만 포함한 Solidity 0.8 인터페이스를 선언합니다.

```solidity
interface IFallout {
    function Fal1out() external payable;
    function owner() external view returns (address);
}
```

Foundry가 구버전 컨트랙트를 별도로 컴파일하게 하고, 테스트에서는 해당 artifact를 직접 배포합니다.

```solidity
falloutContract = IFallout(deployCode("02_Fallout.sol:Fallout"));
```

이 방식은 원본 Solidity 버전과 취약한 동작을 보존하면서도 최신 forge-std를 테스트 환경에서 사용할 수 있게 합니다.

## 취약점의 근본 원인

권한이 필요한 초기화 로직이 생성자가 아니라 제한 없는 공개 함수로 노출되었습니다. 이 함수는 `msg.sender`를 소유자로 지정하면서 초기화가 이미 수행되었는지도 확인하지 않습니다.

더 넓은 관점에서 함수 이름은 보안 통제가 될 수 없습니다. 초기화에는 언어가 제공하는 생성자 또는 명시적인 접근 제어와 일회성 실행을 보장하는 initializer 패턴을 사용해야 합니다. 코드를 빠르게 확인하면 생성자가 존재하는 것처럼 보이지만 실제 배포 bytecode에는 공개 함수가 노출된다는 점에서 특히 위험한 유형입니다.

## 권장 완화 방법

- 배포 시 초기화에는 `constructor` 키워드를 사용합니다.
- 함수 이름에 의존해 생성자 동작을 구현하지 않습니다.
- 프록시 기반 시스템의 initializer에는 일회성 초기화 보호 장치를 적용합니다.
- 초기화를 반복해서 실행할 수 없는지 테스트합니다.
- 필요한 경우 OpenZeppelin의 `Ownable`처럼 검증된 소유권 컴포넌트를 사용합니다.

## 테스트 실행

```bash
forge test --match-path test/02_Fallout.t.sol -vvv
```

전체 호출 추적을 확인하려면:

```bash
forge test --match-path test/02_Fallout.t.sol -vvvv
```

## 학습 정리

권한 초기화 로직의 문자 하나만 잘못되어도 전체 소유권이 노출될 수 있습니다. 생성자와 initializer도 컨트랙트의 접근 제어 영역에 포함하여 검토해야 합니다.
