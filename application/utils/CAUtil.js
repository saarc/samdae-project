"use strict";

exports.buildCAClient = (FabricCAServices, ccp, caHostName) => {
    // 1. 연결정보 구조체에서 필요 정보 가져오기 (CA인증서, url, caName)
    const caInfo = ccp.certificateAuthorities[caHostName];
    const caTLSCACerts = caInfo.tlsCACerts.pem;
    // 2. CA연결 객체화
    const caClient = new FabricCAServices(caInfo.url, { trustedRoots: caTLSCACerts, verify: false}, caInfo.caName);
    console.log(`Built  a CA Client named ${caInfo.caName}`);

    // 3. CA객체 반환
    return caClient;
};

exports.enrollAdmin = async (caClient, wallet, orgMspId, adminUserId, adminUserPasswd) => {
    try {
        // 1. 지갑에서 admin 인증서 존재여부 확인
        const identity = await wallet.get(adminUserId);
        if (identity) {
            console.log("An identity for the admin user already exists in the wallet");
            throw new Error("An identity for the admin user already exists in the wallet");
            return;
        }
        // 2. ca객체를 이용하여 admin enroll
        const enrollment = await caClient.enroll({ enrollmentID: adminUserId, enrollmentSecret: adminUserPasswd})
        // 3. x.509형식으로 인증서 저장
        const x509Identity = {
            credentials: {
                certificate: enrollment.certificate,
                privateKey: enrollment.key.toBytes(),
            },
            mspId: orgMspId,
            type: "X.509",
        };
        await wallet.put(adminUserId, x509Identity);
        console.log("Successfully enrolled admin user and imported it into the wallet");
    } catch (error) {
        console.error(`Failed to enroll admin user : ${error}`);
        throw error;
    }
};

exports.registerAndEnrollUser = async (caClient, wallet, orgMspId, adminUserId, userId, affiliation) => {
    try {
        // 1. 사용자 인증서 같은이름 존재여부 확인
        const userIdentity = await wallet.get(userId);
        if (userIdentity) {
            console.log(`An identity for the user ${userId} already exists in the wallet`);
            throw new Error(`An identity for the user ${userId} already exists in the wallet`);
            return;
        }
        // 2. admin 인증서 존재여부 확인 (없으면 오류)
        const adminIdentity = await wallet.get(adminUserId);
        if (!adminIdentity) {
            console.log("An identity for the admin user does not exist in the wallet");
            console.log("Enroll the admin user before retrying");
            throw new Error("An identity for the admin user does not exit in the wallet");
            return;
        }
        // 3. admin 인증서 가져오기
        const provider = wallet.getProviderRegistry().getProvider(adminIdentity.type);
        const adminUser = await provider.getUserContext(adminIdentity, adminUserId);

        // 4. admin 인증서를 이용하여 user register
        const secret = await caClient.register(
            {
                affiliation: affiliation,
                enrollmentID: userId,
                role: "client",
            },
            adminUser
        );
        // 5. 사용자 enroll
        const enrollment = await caClient.enroll({
            enrollmentID: userId,
            enrollmentSecret: secret,
        });
        // 6. x.509형식으로 사용자 인증서 지갑에 저장
        const x509Identity = {
            credentials: {
                certificate: enrollment.certificate,
                privateKey: enrollment.key.toBytes(),
            },
            mspId: orgMspId,
            type: "X.509",
        };
        await wallet.put(userId, x509Identity);
        console.log(`Successfully registered and enrolled user ${userId} and imported it into the wallet`);
    } catch (error) {
        console.error(`Failed to register user : ${error}`);
        throw error;
    }
};