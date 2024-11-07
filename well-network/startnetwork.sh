#!/bin/bash

# 1. 환경 변수 설정
export FABRIC_CFG_PATH=${PWD}

# 2. id생성
# cryptogen generate --config=./crypto-config.yaml --output="organizations"

# ca 컨테이너 수행
COMPOSE_PROJECT_NAME=net docker-compose -f docker-compose.yaml up -d ca_org1 ca_org2 ca_org3 ca_orderer
sleep 5

# shell script import
. registerEnroll.sh

# 인증서 생성 함수 수행
createOrg1
createOrg2
createOrg3
createOrderer

# 3. genesis.block 생성
configtxgen -profile ThreeOrgsOrdererGenesis -channelID system-channel -outputBlock ./system-genesis-block/genesis.block

# 4. docker-compose 수행
COMPOSE_PROJECT_NAME=net docker-compose -f docker-compose.yaml up -d orderer.example.com peer0.org1.example.com peer0.org2.example.com peer0.org3.example.com
