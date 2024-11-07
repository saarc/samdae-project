#!/bin/bash

# 환경설정 
export FABRIC_CFG_PATH=${PWD}

echo "************************* SUPPLYNET CHANNEL *******************************"
CHANNEL_NAME="supplynet"

# 채널 트랜젝션 생성
configtxgen -profile SupplyOrgsChannel -outputCreateChannelTx ./channel-artifacts/${CHANNEL_NAME}.tx -channelID $CHANNEL_NAME

# org1 연결 환경변수 설정
export ORDERER_CA=${PWD}/organizations/ordererOrganizations/example.com/orderers/orderer.example.com/msp/tlscacerts/tlsca.example.com-cert.pem
export CORE_PEER_TLS_ENABLED=true
export CORE_PEER_LOCALMSPID="Org1MSP"
export CORE_PEER_TLS_ROOTCERT_FILE=${PWD}/organizations/ordererOrganizations/example.com/orderers/orderer.example.com/msp/tlscacerts/tlsca.example.com-cert.pem
export CORE_PEER_MSPCONFIGPATH=${PWD}/organizations/peerOrganizations/org1.example.com/users/Admin@org1.example.com/msp
export CORE_PEER_ADDRESS=localhost:7051

# 채널 블럭생성
peer channel create \
    -o localhost:11050 \
    -c $CHANNEL_NAME \
    --ordererTLSHostnameOverride orderer.example.com \
    -f ./channel-artifacts/${CHANNEL_NAME}.tx \
    --outputBlock ./channel-artifacts/${CHANNEL_NAME}.block \
    --tls \
    --cafile $ORDERER_CA

sleep 3

# 채널 조인 org1
export CORE_PEER_TLS_ROOTCERT_FILE=${PWD}/organizations/peerOrganizations/org1.example.com/peers/peer0.org1.example.com/tls/ca.crt

peer channel join -b ./channel-artifacts/${CHANNEL_NAME}.block

sleep 3

# 채널 조인 org2
export CORE_PEER_LOCALMSPID="Org2MSP"
export CORE_PEER_TLS_ROOTCERT_FILE=${PWD}/organizations/peerOrganizations/org2.example.com/peers/peer0.org2.example.com/tls/ca.crt
export CORE_PEER_MSPCONFIGPATH=${PWD}/organizations/peerOrganizations/org2.example.com/users/Admin@org2.example.com/msp
export CORE_PEER_ADDRESS=localhost:8051

peer channel join -b ./channel-artifacts/${CHANNEL_NAME}.block

sleep 3

## org1 앵커 tx 생성
configtxgen -profile SupplyOrgsChannel -outputAnchorPeersUpdate ./channel-artifacts/sorg1anchor.tx -channelID ${CHANNEL_NAME} -asOrg Org1MSP

## org2 앵커 tx 생성
configtxgen -profile SupplyOrgsChannel -outputAnchorPeersUpdate ./channel-artifacts/sorg2anchor.tx -channelID ${CHANNEL_NAME} -asOrg Org2MSP

## org1 환경설정
export CORE_PEER_LOCALMSPID="Org1MSP"
export CORE_PEER_TLS_ROOTCERT_FILE=${PWD}/organizations/peerOrganizations/org1.example.com/peers/peer0.org1.example.com/tls/ca.crt
export CORE_PEER_MSPCONFIGPATH=${PWD}/organizations/peerOrganizations/org1.example.com/users/Admin@org1.example.com/msp
export CORE_PEER_ADDRESS=localhost:7051
## org1 앵커 tx 채널 update
peer channel update -f ./channel-artifacts/sorg1anchor.tx -c ${CHANNEL_NAME} -o localhost:11050 --ordererTLSHostnameOverride orderer.example.com --tls --cafile $ORDERER_CA

sleep 3

## org2 환경설정
export CORE_PEER_LOCALMSPID="Org2MSP"
export CORE_PEER_TLS_ROOTCERT_FILE=${PWD}/organizations/peerOrganizations/org2.example.com/peers/peer0.org2.example.com/tls/ca.crt
export CORE_PEER_MSPCONFIGPATH=${PWD}/organizations/peerOrganizations/org2.example.com/users/Admin@org2.example.com/msp
export CORE_PEER_ADDRESS=localhost:8051
## org2 앵커 tx 채널 update
peer channel update -f ./channel-artifacts/sorg2anchor.tx -c ${CHANNEL_NAME} -o localhost:11050 --ordererTLSHostnameOverride orderer.example.com --tls --cafile $ORDERER_CA

sleep 3

echo "************************* GREENNET CHANNEL *******************************"

CHANNEL_NAME="greennet"

# 채널 트랜젝션 생성
configtxgen -profile GreenOrgsChannel -outputCreateChannelTx ./channel-artifacts/${CHANNEL_NAME}.tx -channelID $CHANNEL_NAME

# org2 연결 환경변수 설정
export ORDERER_CA=${PWD}/organizations/ordererOrganizations/example.com/orderers/orderer.example.com/msp/tlscacerts/tlsca.example.com-cert.pem
export CORE_PEER_TLS_ENABLED=true
export CORE_PEER_LOCALMSPID="Org2MSP"
export CORE_PEER_TLS_ROOTCERT_FILE=${PWD}/organizations/ordererOrganizations/example.com/orderers/orderer.example.com/msp/tlscacerts/tlsca.example.com-cert.pem
export CORE_PEER_MSPCONFIGPATH=${PWD}/organizations/peerOrganizations/org2.example.com/users/Admin@org2.example.com/msp
export CORE_PEER_ADDRESS=localhost:8051

# 채널 블럭생성
peer channel create \
    -o localhost:11050 \
    -c $CHANNEL_NAME \
    --ordererTLSHostnameOverride orderer.example.com \
    -f ./channel-artifacts/${CHANNEL_NAME}.tx \
    --outputBlock ./channel-artifacts/${CHANNEL_NAME}.block \
    --tls \
    --cafile $ORDERER_CA

sleep 3

# 채널 조인 org2
export CORE_PEER_TLS_ROOTCERT_FILE=${PWD}/organizations/peerOrganizations/org2.example.com/peers/peer0.org2.example.com/tls/ca.crt

peer channel join -b ./channel-artifacts/${CHANNEL_NAME}.block

sleep 3

# 채널 조인 org3
export CORE_PEER_LOCALMSPID="Org3MSP"
export CORE_PEER_TLS_ROOTCERT_FILE=${PWD}/organizations/peerOrganizations/org3.example.com/peers/peer0.org3.example.com/tls/ca.crt
export CORE_PEER_MSPCONFIGPATH=${PWD}/organizations/peerOrganizations/org3.example.com/users/Admin@org3.example.com/msp
export CORE_PEER_ADDRESS=localhost:9051

peer channel join -b ./channel-artifacts/${CHANNEL_NAME}.block

sleep 3

## org2 앵커 tx 생성
configtxgen -profile GreenOrgsChannel -outputAnchorPeersUpdate ./channel-artifacts/gorg2anchor.tx -channelID ${CHANNEL_NAME} -asOrg Org2MSP

## org3 앵커 tx 생성
configtxgen -profile GreenOrgsChannel -outputAnchorPeersUpdate ./channel-artifacts/gorg3anchor.tx -channelID ${CHANNEL_NAME} -asOrg Org3MSP

## org2 환경설정
export CORE_PEER_LOCALMSPID="Org2MSP"
export CORE_PEER_TLS_ROOTCERT_FILE=${PWD}/organizations/peerOrganizations/org2.example.com/peers/peer0.org2.example.com/tls/ca.crt
export CORE_PEER_MSPCONFIGPATH=${PWD}/organizations/peerOrganizations/org2.example.com/users/Admin@org2.example.com/msp
export CORE_PEER_ADDRESS=localhost:8051
## org2 앵커 tx 채널 update
peer channel update -f ./channel-artifacts/gorg2anchor.tx -c ${CHANNEL_NAME} -o localhost:11050 --ordererTLSHostnameOverride orderer.example.com --tls --cafile $ORDERER_CA

sleep 3

## org3 환경설정
export CORE_PEER_LOCALMSPID="Org3MSP"
export CORE_PEER_TLS_ROOTCERT_FILE=${PWD}/organizations/peerOrganizations/org3.example.com/peers/peer0.org3.example.com/tls/ca.crt
export CORE_PEER_MSPCONFIGPATH=${PWD}/organizations/peerOrganizations/org3.example.com/users/Admin@org3.example.com/msp
export CORE_PEER_ADDRESS=localhost:9051
## org3 앵커 tx 채널 update
peer channel update -f ./channel-artifacts/gorg3anchor.tx -c ${CHANNEL_NAME} -o localhost:11050 --ordererTLSHostnameOverride orderer.example.com --tls --cafile $ORDERER_CA

sleep 3

