#!/bin/bash

docker build -f openvscode-server-linux-build-agent.Dockerfile -t ruotiantang/openvscode-server-linux-build-agent:bionic-x64 .

docker build -f Dockerfile -t ruotiantang/openvscode-server-demo:1.0 .
