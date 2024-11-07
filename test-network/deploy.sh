#!/bin/bash

export FABRIC_CFG_PATH=~/fabric-samples/config

pushd ~/fabric-samples/test-network

    ./network.sh deployCC -ccn utxo -ccp ~/dev/samdae-project/contract/utxo-token -ccl go -c donachannel

popd