#!/bin/bash

setOrg1() {
    echo "SETTING - ORG1 VARIABLE"
    export CORE_PEER_LOCALMSPID="Org1MSP"
    export CORE_PEER_MSPCONFIGPATH=${TEST_NETWORK_DIR}/organizations/peerOrganizations/org1.example.com/users/Admin@org1.example.com/msp
    export CORE_PEER_ADDRESS=localhost:7051
    export PEER0_ORG1_CA=${TEST_NETWORK_DIR}/organizations/peerOrganizations/org1.example.com/peers/peer0.org1.example.com/tls/ca.crt
    export CORE_PEER_TLS_ROOTCERT_FILE=$PEER0_ORG1_CA
}

setOrg2() {
    echo "SETTING - ORG1 VARIABLE"
    export CORE_PEER_LOCALMSPID="Org2MSP"
    export PEER0_ORG2_CA=${TEST_NETWORK_DIR}/organizations/peerOrganizations/org2.example.com/peers/peer0.org2.example.com/tls/ca.crt
    export CORE_PEER_TLS_ROOTCERT_FILE=$PEER0_ORG2_CA
    export CORE_PEER_MSPCONFIGPATH=${TEST_NETWORK_DIR}/organizations/peerOrganizations/org2.example.com/users/Admin@org2.example.com/msp
    export CORE_PEER_ADDRESS=localhost:8051
}

# 환경설정
export FABRIC_CFG_PATH=~/fabric-samples/config
export TEST_NETWORK_DIR=${PROJ_DIR}/well-network
export CORE_PEER_TLS_ENABLED=true

CHAINCODE_NAME=samdae
CHANNEL_NAME=supplynet
VER=1.0
SEQ=1

# 체인코드 패키지
echo "CHAICODE - 1. PACKAGE"
set -x
peer lifecycle chaincode package ${CHAINCODE_NAME}.tar.gz --path ./samdae --lang golang --label ${CHAINCODE_NAME}_${VER}
{ set +x; } 2>/dev/null

# 체인코드 설치하기
# ORG1 관리자 인증서, MSPID, PEER주소와포트 환경변수 설정
setOrg1

# ORG1에 
echo "CHAICODE - 2. INSTALL to org1"
set -x
peer lifecycle chaincode install ${CHAINCODE_NAME}.tar.gz 
{ set +x; } 2>/dev/null

# ORG2 관리자 인증서, MSPID, PEER주소와포트 환경변수 설정
setOrg2

# ORG2에
peer lifecycle chaincode install ${CHAINCODE_NAME}.tar.gz 

# 체인코드 ID조회하고 가져오기
peer lifecycle chaincode queryinstalled > log.txt
PACKAGE_ID=$(sed -n "/${CHAINCODE_NAME}_${VER}/{s/^Package ID: //; s/, Label:.*$//; p;}" log.txt)

# 체인코드 승인하기
export ORDERER_CA=${TEST_NETWORK_DIR}/organizations/ordererOrganizations/example.com/orderers/orderer.example.com/msp/tlscacerts/tlsca.example.com-cert.pem

# ORG1에서
setOrg1
peer lifecycle chaincode approveformyorg \
    -o localhost:11050 \
    --ordererTLSHostnameOverride orderer.example.com \
    --tls \
    --cafile $ORDERER_CA \
    --channelID ${CHANNEL_NAME} \
    --name ${CHAINCODE_NAME} \
    --version ${VER} \
    --package-id ${PACKAGE_ID} \
    --sequence ${SEQ}
    
sleep 3

# ORG2에서
setOrg2
peer lifecycle chaincode approveformyorg \
    -o localhost:11050 \
    --ordererTLSHostnameOverride orderer.example.com \
    --tls \
    --cafile $ORDERER_CA \
    --channelID ${CHANNEL_NAME} \
    --name ${CHAINCODE_NAME} \
    --version ${VER} \
    --package-id ${PACKAGE_ID} \
    --sequence ${SEQ}

sleep 3

# 커밋 승인 확인하기
peer lifecycle chaincode checkcommitreadiness --channelID ${CHANNEL_NAME} --name ${CHAINCODE_NAME} --version 1 --sequence 1 --output json

# 체인코드 커밋하기
peer lifecycle chaincode commit \
    -o localhost:11050 \
    --ordererTLSHostnameOverride orderer.example.com \
    --tls \
    --cafile $ORDERER_CA \
    --channelID ${CHANNEL_NAME} \
    --name ${CHAINCODE_NAME} \
    --peerAddresses localhost:7051 \
    --tlsRootCertFiles $PEER0_ORG1_CA \
    --peerAddresses localhost:8051 \
    --tlsRootCertFiles $PEER0_ORG2_CA \
    --version ${VER} \
    --sequence ${SEQ}

sleep 3

# TEST
# 1. AddCoffee
echo "CHAICODE - 1. TEST : invoke AddCoffee PB paulbasset"
set -x
peer chaincode invoke \
    -o localhost:11050 \
    --ordererTLSHostnameOverride orderer.example.com \
    --tls \
    --cafile $ORDERER_CA \
    -C ${CHANNEL_NAME} \
    -n ${CHAINCODE_NAME} \
    --peerAddresses localhost:7051 \
    --tlsRootCertFiles $PEER0_ORG1_CA \
    --peerAddresses localhost:8051 \
    --tlsRootCertFiles $PEER0_ORG2_CA \
    -c '{"function":"AddCoffee","Args":["PB","paulbasset"]}'
res=$?
{ set +x; } 2>/dev/null
sleep 3

echo "CHAICODE - 2. TEST : invoke PurchaseCoffee S001 U001 PB "
set -x
peer chaincode invoke \
    -o localhost:11050 \
    --ordererTLSHostnameOverride orderer.example.com \
    --tls \
    --cafile $ORDERER_CA \
    -C ${CHANNEL_NAME} \
    -n ${CHAINCODE_NAME} \
    --peerAddresses localhost:7051 \
    --tlsRootCertFiles $PEER0_ORG1_CA \
    --peerAddresses localhost:8051 \
    --tlsRootCertFiles $PEER0_ORG2_CA \
    -c '{"function":"PurchaseCoffee","Args":["S001","U001", "PB"]}'
res=$?
{ set +x; } 2>/dev/null
sleep 3


echo "CHAICODE - 3. TEST : invoke RegisterRate S001 PB"
set -x
peer chaincode invoke \
    -o localhost:11050 \
    --ordererTLSHostnameOverride orderer.example.com \
    --tls \
    --cafile $ORDERER_CA \
    -C ${CHANNEL_NAME} \
    -n ${CHAINCODE_NAME} \
    --peerAddresses localhost:7051 \
    --tlsRootCertFiles $PEER0_ORG1_CA \
    --peerAddresses localhost:8051 \
    --tlsRootCertFiles $PEER0_ORG2_CA \
    -c '{"function":"RegisterRate","Args":["S001","PB"]}'
res=$?
{ set +x; } 2>/dev/null
sleep 3

# 2. QueryCoffee
echo "CHAICODE - 4. TEST : query QueryCoffee PB"
set -x
peer chaincode query -C ${CHANNEL_NAME} -n ${CHAINCODE_NAME} -c '{"Args":["QueryCoffee", "PB"]}'
res=$?
{ set +x; } 2>/dev/null

# 3. GetHistory
echo "CHAICODE - 5. TEST : query GetHistory PB "
set -x
peer chaincode query -C ${CHANNEL_NAME} -n ${CHAINCODE_NAME} -c '{"Args":["GetHistory", "PB"]}'
res=$?
{ set +x; } 2>/dev/null