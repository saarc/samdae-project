"use strict";

var express = require('express');

var path = require('path');

var app = express();

// fabric SDK 포함
const {Gateway, Wallets} = require("fabric-network");
const FabricCAServices = require("fabric-ca-client");

// user defined 라이버러리 포함
const { buildCAClient, registerAndEnrollUser, enrollAdmin } = require("./utils/CAUtil.js");
const { buildCCPOrg2, buildWallet } = require("./utils/AppUtil.js");

// 사용 상수 설정
const mspOrg2 = "Org2MSP";
const walletPath = path.join(__dirname, "wallet");
const channelName = 'supplynet';
const chaincodeName = 'samdae';

app.use('/public', express.static('public'));
app.use(express.json());
app.use(express.urlencoded({extended: true}));

app.get('/', (req, res) => {
    res.sendFile(path.join(__dirname,'views','index.html'));
})
app.get('/views/wallet-admin.html', (req, res) => {
    res.sendFile(path.join(__dirname,'views','wallet-admin.html'));
})
app.get('/views/wallet-user.html', (req, res) => {
    res.sendFile(path.join(__dirname,'views','wallet-user.html'));
})
app.get('/views/coffee-register.html', (req, res) => {
    res.sendFile(path.join(__dirname,'views','coffee-register.html'));
})
app.get('/views/coffee-read.html', (req, res) => {
    res.sendFile(path.join(__dirname,'views','coffee-read.html'));
})
app.get('/views/coffee-sale.html', (req, res) => {
    res.sendFile(path.join(__dirname,'views','coffee-sale.html'));
})
app.get('/views/coffee-preference.html', (req, res) => {
    res.sendFile(path.join(__dirname,'views','coffee-preference.html'));
})
app.get('/views/coffee-history.html', (req, res) => {
    res.sendFile(path.join(__dirname,'views','coffee-history.html'));
})

app.post('/cert/admin', async(req, res) => {
    console.log("/cert/admin POST 라우팅");
    const cainfo = req.body.cainfo;
    const adminid = req.body.adminid;
    const adminpw = req.body.adminpw;
    console.log('/cert/admin POST : ', cainfo, adminid, adminpw);
    
    var return_obj = {};

    try {
        // 1. 연결정보 구조체화
        const ccp = buildCCPOrg2();
        // 2. ca연결객체 생성
        const caClient = buildCAClient(FabricCAServices, ccp, cainfo);
        // 3. 지갑객체 생성
        const wallet = await buildWallet(Wallets, walletPath);
        // 4. 관리자 인증서 저장
        await enrollAdmin(caClient, wallet, mspOrg2, adminid, adminpw);

    } catch (error) {
        console.error(`********** FAILED to run the application : ${error}`);
        // web response
        return_obj.result = "failed"
        return_obj.error = `${error}`
        res.json(return_obj);
        return;
    }

    return_obj.result = "success";
    return_obj.message = "Successfully enrolled admin user and imported it into the wallet";
    res.json(return_obj);
});

app.post('/cert/user', async(req, res) => {
    console.log("/cert/user POST 라우팅");
    const cainfo = req.body.cainfo;

    const userid = req.body.userid;
    const adminid = req.body.adminid;
    const affiliation = req.body.affiliation;

    console.log('/cert/user POST : ', cainfo, userid, adminid, affiliation);

    var return_obj = {};

    try {
        // 1. 연결정보 구조체화
        const ccp = buildCCPOrg2();
        // 2. ca연결객체 생성
        const caClient = buildCAClient(FabricCAServices, ccp, cainfo);
        // 3. 지갑객체 생성
        const wallet = await buildWallet(Wallets, walletPath);
        // 4. 관리자 인증서 저장
        await registerAndEnrollUser(caClient, wallet, mspOrg2, adminid, userid, affiliation);

    } catch (error) {
        console.error(`********** FAILED to run the application : ${error}`);
        // web response
        return_obj.result = "failed"
        return_obj.error = `${error}`
        res.json(return_obj);
        return;
    }

    return_obj.result = "success";
    return_obj.message = `Successfully registered and enrolled user ${userid} and imported it into the wallet`;
    res.json(return_obj);

});

// /coffee, POST : AddCoffee
app.post('/coffee', async(req, res) => {
    console.log("/coffee POST 라우팅");
    const userid = req.body.userid;
    const coffeeid = req.body.coffeeid;
    const name = req.body.name;


    console.log(userid, coffeeid, name);

    var return_obj = {};

    try {
        const ccp = buildCCPOrg2();
        const wallet = await buildWallet(Wallets, walletPath);

        var gateway = new Gateway();

        try {
            await gateway.connect(ccp, {wallet, identity: userid, discovery: {enabled:true, asLocalhost: true}});
            const network = await gateway.getNetwork(channelName);
            const contract = network.getContract(chaincodeName);

            let result = await contract.submitTransaction('AddCoffee', coffeeid, name);
            // if(`${result} != ""`){
            //     // 오류 응답
            //     throw Error(`${result.toString}`);
            //     return;
            // } 
        } finally {
            gateway.disconnect();
        }
    } catch (error) {
        // 오류 응답
        console.error(`********** FAILED to create a asset : ${error}`);
        return_obj.result = "failed";
        return_obj.error = `${error}`;
        res.json(return_obj);
        return;
    }
    
    return_obj.result = "success";
    return_obj.message = `Successfully registered a coffee : ${coffeeid}`;
    res.json(return_obj);
    
});

// /coffee, GET : QueryCoffee
app.get('/coffee', async(req, res) => {
    console.log("/coffee GET 라우팅");
    // params 가져오기 query에서 꺼내기
    const userid = req.query.userid;
    const coffeeid = req.query.coffeeid;

    console.log(userid, coffeeid);

    var return_obj = {};
    let result;

    try {
        // 1. 연결정보 구조체화
        const ccp = buildCCPOrg2();

        // 2. 지갑 구조체화
        const wallet = await buildWallet(Wallets, walletPath);

        var gateway = new Gateway();

        try {
            // 3. 게이트웨이 연결
            await gateway.connect(ccp, {wallet, identity: userid, dicovery: {enabled: true, asLocalhost: true}});

            // 4. 채널 객체 가져오기
            const network = await gateway.getNetwork(channelName);

            // 5. 체인코드 객체 가져오기
            const contract = network.getContract(chaincodeName);

            // 6. QueryCoffee수행하기
            result = await contract.submitTransaction('QueryCoffee', coffeeid);
            
        } finally {
            gateway.disconnect();
        }
    } catch (error) {
        // 6.1 실패응답
        console.error(`********** FAILED to read a coffee : ${error}`);
        return_obj.result = 'failed';
        return_obj.error = `${error}`;
        res.json(return_obj);
        return;
    }

    // 6.2 성공 응답
    return_obj.result = 'success';
    return_obj.message = JSON.parse(result);
    res.json(return_obj);

});

// /coffee/history, GET : GetHistory
app.get('/coffee/history', async(req, res) => {
    console.log("/coffee/history GET 라우팅");
    // params 가져오기 query에서 꺼내기
    const userid = req.query.userid;
    const coffeeid = req.query.coffeeid;

    console.log(userid, coffeeid);

    var return_obj = {};
    let result;

    try {
        // 1. 연결정보 구조체화
        const ccp = buildCCPOrg2();

        // 2. 지갑 구조체화
        const wallet = await buildWallet(Wallets, walletPath);

        var gateway = new Gateway();

        try {
            // 3. 게이트웨이 연결
            await gateway.connect(ccp, {wallet, identity: userid, dicovery: {enabled: true, asLocalhost: true}});

            // 4. 채널 객체 가져오기
            const network = await gateway.getNetwork(channelName);

            // 5. 체인코드 객체 가져오기
            const contract = network.getContract(chaincodeName);

            // 6. ReadAsset수행하기
            result = await contract.submitTransaction('GetHistory', coffeeid);
            
        } finally {
            gateway.disconnect();
        }
    } catch (error) {
        // 6.1 실패응답
        console.error(`********** FAILED to read a coffee history : ${error}`);
        return_obj.result = 'failed';
        return_obj.error = `${error}`;
        res.json(return_obj);
        return;
    }

    // 6.2 성공 응답
    return_obj.result = 'success';
    return_obj.message = JSON.parse(result);
    res.json(return_obj);

});

app.listen(3000, () => {
    console.log("3000번 포트로 익스프레스 삼대다방서버 시작됨.");
});