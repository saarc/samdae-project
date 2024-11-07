"use strict";

const fs = require("fs");
const path = require("path");

exports.buildCCPOrg2 = () => {
    // 1. 연결정보 경로 생성 busan-project/network/connection-org1.json
    const ccpPath = path.resolve(__dirname, '..', '..', 'well-network', 'connection-org2.json');
    // 2. 파일 존재여부 확인
    const fileExists = fs.existsSync(ccpPath);
    if(!fileExists) {
        throw new Error(`no such file or directory: ${ccpPath}`);
        return;
    }
    // 3. 파일읽기
    const contents = fs.readFileSync(ccpPath, "utf8");
    // 4. 연결정보 구조체화
    const ccp = JSON.parse(contents);
    // 5. 연결정보 구조체 반환
    console.log(`Loaded the network configuration located at ${ccpPath}`);
    return ccp;
};

exports.buildWallet = async (Wallets, walletPath) => {
    // 지갑경로 검증 후 지갑객체 생성
    let wallet;
    if( walletPath ) {
        wallet = await Wallets.newFileSystemWallet(walletPath);
        console.log(`Built a file system wallet at ${walletPath}`);
    } else {
        console.log("Invalid wallet path");
        throw new Error('Invalid wallet path');
        return ;
    }

    // 지갑객체 반환
    return wallet;
};