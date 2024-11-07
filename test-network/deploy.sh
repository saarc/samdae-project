#!/bin/bash

export FABRIC_CFG_PATH=~/fabric-samples/config

pushd ~/fabric-samples/test-network

    ./network.sh deployCC -ccn samdae -ccp ~/dev/samdae-project/contract/samdae -ccl go -c supplynet

popd
