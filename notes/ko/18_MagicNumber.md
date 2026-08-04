# 18. Magic Number

[English](../en/18_MagicNumber.md) | [한국어](18_MagicNumber.md)

## 문제 목표

런타임 코드가 10바이트 이하이면서 `whatIsTheMeaningOfLife()` 호출에 숫자 `42`를 반환하는 솔버를 배포합니다.

## 핵심 개념

- EVM 바이트코드
- 생성 코드와 런타임 코드
- 스택 기반 opcode 실행
- EVM 메모리
- ABI 인코딩 반환값

## 두 종류의 배포 코드

컨트랙트 배포 트랜잭션은 생성 코드를 실행합니다. 생성 코드가 반환한 바이트가 컨트랙트의 영구적인 런타임 코드로 저장됩니다.

```text
배포 중 생성 코드가 한 번 실행됨
        ↓
생성 코드가 바이트열 반환
        ↓
EVM이 해당 바이트열을 런타임 코드로 저장
        ↓
이후 호출은 런타임 코드만 실행
```

테스트에서 사용하는 전체 바이트열은 다음과 같습니다.

```text
600a600c600039600a6000f3 602a60805260206080f3
└──── 생성 코드: 12바이트 ────┘ └─ 런타임: 10바이트 ─┘
```

## 런타임 코드

10바이트 런타임 프로그램은 다음과 같습니다.

```text
60 2a  PUSH1 0x2a   십진수 42를 스택에 추가
60 80  PUSH1 0x80   메모리 오프셋 128 추가
52     MSTORE       memory[0x80]에 42를 32바이트 워드로 저장
60 20  PUSH1 0x20   반환 길이 32 추가
60 80  PUSH1 0x80   반환 시작 오프셋 128 추가
f3     RETURN       memory[0x80 : 0xa0] 반환
```

`MSTORE`는 항상 완전한 32바이트 워드를 기록합니다. 이 32바이트를 반환하면 값이 `42`인 `uint256`의 ABI 표현과 일치합니다.

런타임 프로그램은 calldata나 4바이트 함수 selector를 검사하지 않습니다. 어떤 호출이든 같은 인코딩 값을 받지만 이 레벨이 요구하는 인터페이스 동작에는 충분합니다.

## 생성 코드

앞의 12바이트는 뒤에 붙은 런타임 바이트를 메모리로 복사하고 반환합니다.

```text
60 0a  PUSH1 0x0a   런타임 길이 = 10바이트
60 0c  PUSH1 0x0c   런타임 시작 = 바이트 오프셋 12
60 00  PUSH1 0x00   대상 메모리 오프셋 = 0
39     CODECOPY     code[12:22]를 memory[0:10]에 복사
60 0a  PUSH1 0x0a   반환 길이 = 10
60 00  PUSH1 0x00   반환 오프셋 = 0
f3     RETURN       복사한 바이트를 런타임 코드로 설치
```

오프셋 `0x0c`는 생성 프로그램 자체의 길이와 정확히 같습니다. 생성 코드는 배포된 컨트랙트에 남지 않습니다.

## CREATE로 배포

Solidity는 일반적으로 생성 코드와 런타임 코드를 자동 생성합니다. 이 테스트는 직접 만든 바이트를 `CREATE` opcode에 전달합니다.

```solidity
address solver;

assembly {
    solver := create(
        0,
        add(creationCode, 0x20),
        mload(creationCode)
    )
}
```

동적 `bytes` 값은 첫 32바이트에 길이를 저장합니다. `add(creationCode, 0x20)`은 길이 워드를 건너뛰고 실제 바이트코드 시작 위치를 가리킵니다.

## Foundry 테스트

```solidity
assertNotEq(solver, address(0));

target.setSolver(solver);
assertEq(target.solver(), solver);
assertEq(solver.code.length, 10);

(bool success, bytes memory returnData) = solver.staticcall(
    abi.encodeWithSignature("whatIsTheMeaningOfLife()")
);

assertTrue(success);
assertEq(returnData.length, 32);
assertEq(abi.decode(returnData, (uint256)), 42);
```

## 문제의 성격

이 레벨은 일반적인 컨트랙트 결함보다 고수준 Solidity가 필수가 아니라는 사실을 보여줍니다. 올바르게 인코딩된 데이터를 반환한다면 어떤 유효한 EVM 런타임 프로그램도 인터페이스를 만족할 수 있습니다.

## 권장 엔지니어링 방법

- 코드 크기 제약이 중요하다면 런타임 코드 크기와 실제 동작을 모두 검증합니다.
- 저수준 호출 성공이 의미 있는 반환 데이터를 보장하지 않는다는 점을 기억합니다.
- 디코딩 전에 반환 데이터 길이를 확인합니다.
- 측정된 제약이 수동 바이트코드를 정당화하지 않는다면 유지보수 가능한 Solidity를 사용합니다.
- 저수준 코드의 모든 opcode, 스택 가정, 오프셋과 반환 형식을 문서화합니다.

## 테스트 실행

```bash
forge test --match-path test/18_MagicNumber.t.sol -vvv
```

## 학습 정리

배포 코드는 다른 프로그램을 반환하는 프로그램입니다. 이 구분을 이해하면 생성 코드는 설치하고 런타임 코드는 호출에 응답한다는 관점으로 EVM 바이트코드를 분석할 수 있습니다.
