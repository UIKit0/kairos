#!/usr/bin/env bash

# Install cappuccino and cardano
if [ ! -d ./src/main/webapp/Frameworks ]; then
    capp gen -f ./src/main/webapp
fi
