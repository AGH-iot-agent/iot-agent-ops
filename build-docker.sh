#!/usr/bin/env bash

set -euo pipefail

docker build -t my-gha-runner:java -f Dockerfile.runner .