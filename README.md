# samdae-project

# 선행조건
hyperledger fabric 2.2.15 버전 설치
go1.21.6
node v20.17.0
docker 24.0.7
docker-compose 1.29.2
도커네트워크 초기화
```
docker rm -f $(docker ps -aq)
docker rmi -f $(docker images dev-* -q)
docker network prune
docker volume prune

docker ps -a
docker network ls
docker volume ls
docker images dev-*
```

#  네트워크 수행
## well-network 내 디렉토리 생성
channel-artifacts
organizations
system-genesis-block

## 준비물생성+fabric구성
`chmod +x *.sh`
`./startnetwork.sh`
## 채널 생성
`./createchannel.sh`
## 연결정보생성
`./ccp-generate.sh`

# 체인코드 설치 배포
## 라이브러리 다운로드
contract/samdae 내에서
`go get "github.com/hyperledger/fabric-contract-api-go/contractapi"`
`go mod vendor`
## contract directory 에서 배포 쉘스크립트 수행
`chmod +x *.sh`
`./deploy_to_well.sh`

# 어플리케이션
## application 디렉토리에서 노드모듈 다운로드
`npm install`
## 서버시작 
`node server.js`

# 웹브라우저에서 접속 후 테스트
http://localhost:3000

# 랜딩 지갑 - 기능 - 블록체인 데시보드  페이지 확인
