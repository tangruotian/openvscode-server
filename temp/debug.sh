#!/bin/bash

docker build -f openvscode-server-linux-build-agent.Dockerfile -t ruotiantang/openvscode-server-linux-build-agent:bionic-x64 .

docker build -f Dockerfile -t mirrors.tencent.com/ruotiantang/openvscode-server-demo:1.1 .
