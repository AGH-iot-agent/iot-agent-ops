#!/usr/bin/env bash

GH_TOKEN=${GH_TOKEN:-$(cat .gh_token)}

for i in {1..5}; do
    docker run -d \
        --name gha-runner_$i \
        -e ORG_URL=https://github.com/AGH-iot-agent \
        -e RUNNER_NAME=runner-$i \
        -e RUNNER_TOKEN=$GH_TOKEN \
        -e RUNNER_WORKDIR=/tmp/runner \
        -v /var/run/docker.sock:/var/run/docker.sock \
        -v /mnt/storage:/mnt/storage \
        --restart always \
        ghcr.io/actions/runner:latest