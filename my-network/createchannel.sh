#!/bin/bash

# 환경설정 
export FABRIC_CFG_PATH=${PWD}

CHANNEL_NAME="mychannel"

# 채널 트랜젝션 생성
configtxgen -profile FourOrgsChannel -outputCreateChannelTx ./channel-artifacts/${CHANNEL_NAME}.tx -channelID $CHANNEL_NAME

# org1 연결 환경변수 설정
export ORDERER_CA=${PWD}/organizations/ordererOrganizations/example.com/orderers/orderer.example.com/msp/tlscacerts/tlsca.example.com-cert.pem
export CORE_PEER_TLS_ENABLED=true
export CORE_PEER_LOCALMSPID="Org1MSP"
export CORE_PEER_TLS_ROOTCERT_FILE=${PWD}/organizations/ordererOrganizations/example.com/orderers/orderer.example.com/msp/tlscacerts/tlsca.example.com-cert.pem
export CORE_PEER_MSPCONFIGPATH=${PWD}/organizations/peerOrganizations/org1.example.com/users/Admin@org1.example.com/msp
export CORE_PEER_ADDRESS=localhost:7051

# 채널 블럭생성
peer channel create \
    -o localhost:7050 \
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

# 채널 조인 org3
export CORE_PEER_LOCALMSPID="Org3MSP"
export CORE_PEER_TLS_ROOTCERT_FILE=${PWD}/organizations/peerOrganizations/org3.example.com/peers/peer0.org3.example.com/tls/ca.crt
export CORE_PEER_MSPCONFIGPATH=${PWD}/organizations/peerOrganizations/org3.example.com/users/Admin@org3.example.com/msp
export CORE_PEER_ADDRESS=localhost:9051

peer channel join -b ./channel-artifacts/${CHANNEL_NAME}.block

sleep 3

# 채널 조인 org4
export CORE_PEER_LOCALMSPID="Org4MSP"
export CORE_PEER_TLS_ROOTCERT_FILE=${PWD}/organizations/peerOrganizations/org4.example.com/peers/peer0.org4.example.com/tls/ca.crt
export CORE_PEER_MSPCONFIGPATH=${PWD}/organizations/peerOrganizations/org4.example.com/users/Admin@org4.example.com/msp
export CORE_PEER_ADDRESS=localhost:10051

peer channel join -b ./channel-artifacts/${CHANNEL_NAME}.block

sleep 3

## org1 앵커 tx 생성
configtxgen -profile FourOrgsChannel -outputAnchorPeersUpdate ./channel-artifacts/org1anchor.tx -channelID ${CHANNEL_NAME} -asOrg Org1MSP

## org2 앵커 tx 생성
configtxgen -profile FourOrgsChannel -outputAnchorPeersUpdate ./channel-artifacts/org2anchor.tx -channelID ${CHANNEL_NAME} -asOrg Org2MSP

## org3 앵커 tx 생성
configtxgen -profile FourOrgsChannel -outputAnchorPeersUpdate ./channel-artifacts/org3anchor.tx -channelID ${CHANNEL_NAME} -asOrg Org3MSP

## org4 앵커 tx 생성
configtxgen -profile FourOrgsChannel -outputAnchorPeersUpdate ./channel-artifacts/org4anchor.tx -channelID ${CHANNEL_NAME} -asOrg Org4MSP

## org1 환경설정
export CORE_PEER_LOCALMSPID="Org1MSP"
export CORE_PEER_TLS_ROOTCERT_FILE=${PWD}/organizations/peerOrganizations/org1.example.com/peers/peer0.org1.example.com/tls/ca.crt
export CORE_PEER_MSPCONFIGPATH=${PWD}/organizations/peerOrganizations/org1.example.com/users/Admin@org1.example.com/msp
export CORE_PEER_ADDRESS=localhost:7051
## org1 앵커 tx 채널 update
peer channel update -f ./channel-artifacts/org1anchor.tx -c ${CHANNEL_NAME} -o localhost:7050 --ordererTLSHostnameOverride orderer.example.com --tls --cafile $ORDERER_CA

sleep 3

## org2 환경설정
export CORE_PEER_LOCALMSPID="Org2MSP"
export CORE_PEER_TLS_ROOTCERT_FILE=${PWD}/organizations/peerOrganizations/org2.example.com/peers/peer0.org2.example.com/tls/ca.crt
export CORE_PEER_MSPCONFIGPATH=${PWD}/organizations/peerOrganizations/org2.example.com/users/Admin@org2.example.com/msp
export CORE_PEER_ADDRESS=localhost:8051
## org2 앵커 tx 채널 update
peer channel update -f ./channel-artifacts/org2anchor.tx -c ${CHANNEL_NAME} -o localhost:7050 --ordererTLSHostnameOverride orderer.example.com --tls --cafile $ORDERER_CA

sleep 3

## org3 환경설정
export CORE_PEER_LOCALMSPID="Org3MSP"
export CORE_PEER_TLS_ROOTCERT_FILE=${PWD}/organizations/peerOrganizations/org3.example.com/peers/peer0.org3.example.com/tls/ca.crt
export CORE_PEER_MSPCONFIGPATH=${PWD}/organizations/peerOrganizations/org3.example.com/users/Admin@org3.example.com/msp
export CORE_PEER_ADDRESS=localhost:9051
## org1 앵커 tx 채널 update
peer channel update -f ./channel-artifacts/org3anchor.tx -c ${CHANNEL_NAME} -o localhost:7050 --ordererTLSHostnameOverride orderer.example.com --tls --cafile $ORDERER_CA

sleep 3

## org4 환경설정
export CORE_PEER_LOCALMSPID="Org4MSP"
export CORE_PEER_TLS_ROOTCERT_FILE=${PWD}/organizations/peerOrganizations/org4.example.com/peers/peer0.org4.example.com/tls/ca.crt
export CORE_PEER_MSPCONFIGPATH=${PWD}/organizations/peerOrganizations/org4.example.com/users/Admin@org4.example.com/msp
export CORE_PEER_ADDRESS=localhost:10051
## org1 앵커 tx 채널 update
peer channel update -f ./channel-artifacts/org4anchor.tx -c ${CHANNEL_NAME} -o localhost:7050 --ordererTLSHostnameOverride orderer.example.com --tls --cafile $ORDERER_CA

