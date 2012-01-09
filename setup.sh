#!/usr/bin/env bash

# Install cappuccino and cardano
if [ ! -d ./src/main/webapp/Frameworks ]; then
    capp gen -f ./src/main/webapp
fi

if [ ! -d ./misc/cardano/cardano ]; then
    tar xvf ./misc/cardano/cardano.tar.gz -C ./misc/cardano/
fi

cp -R ./misc/cardano/cardano/Cardano ./src/main/webapp/Frameworks/
cp -R ./misc/cardano/cardano/Debug ./src/main/webapp/Frameworks/
