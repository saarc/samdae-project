#!/bin/bash

export FABRIC_CFG_PATH=~/fabric-samples/config

pushd ~/fabric-samples/test-network

    ./network.sh down
    ./network.sh up createChannel -ca -c donachannel

    sleep 3
    
    docker rm -f cli

popd