# governance-contract
Governance contract

## Preequiste

1. Docker
   
   Install at https://docs.docker.com/install

2. Install solc 0.4.24

``` 
    $ docker pull ethereum/solc:0.4.24
    $ cp dockers/solc /usr/local/bin/solc
```

## Install 

1. Libraries

```
$ npm install
```

2. Analyzer

```
$ npm run install_analyzer
```

## Run

### Compile

```
$ npm run compile
```

### Test

```
$ npm run test
```

### Coverage

```
$ npm run coverage
```

### Flatten

```
$ npm run flatten
```

## TODO History

### 2025-11-26
- [완료] 코드 분석 및 개선사항 도출
- [완료] getStakerAddr 함수 버그 수정 - 반환값 검증 추가
- [완료] 매직 넘버를 상수로 변경 (5001, 10000 등)
- [완료] checkUnfinalized 로직 정리 및 주석 제거
- [완료] removeMember 배열 재정렬 로직 개선 (헬퍼 함수로 분리)
- [완료] 가스 최적화 - unchecked 블록 추가
- [완료] createVote 함수에 검증 추가 (staker != ZERO, memberLen > 0)
- [완료] finalizeEndedVote 접근 제어 개선
- [완료] reInit 함수 인덱스 버그 수정 (0부터 시작 → 1부터 시작)
- [완료] .cursorrules 파일 생성 및 Git workflow 규칙 추가
