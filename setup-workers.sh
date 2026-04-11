#!/usr/bin/env bash
set -euo pipefail

ORG="AGH-iot-agent"
MAX_RUNNERS=5

GH_TOKEN=${GH_TOKEN:-$(cat .gh_token)}

echo "Fetching registration token..."

REG_TOKEN=$(curl -s -X POST \
  -H "Authorization: Bearer $GH_TOKEN" \
  -H "Accept: application/vnd.github+json" \
  "https://api.github.com/orgs/$ORG/actions/runners/registration-token" \
  | jq -r .token)

if [ -z "$REG_TOKEN" ] || [ "$REG_TOKEN" == "null" ]; then
  echo "Failed to get token"
  exit 1
fi

echo "Checking running runners..."

RUNNING=$(docker ps --format '{{.Names}}' | grep -c "gha-runner" || true)

echo "Currently running: $RUNNING"

AVAILABLE=$((MAX_RUNNERS - RUNNING))

if [ "$AVAILABLE" -le 0 ]; then
  echo "Max runners already running ($MAX_RUNNERS)"
  exit 0
fi

echo "Starting $AVAILABLE new runner(s)..."

for i in $(seq 1 $AVAILABLE); do
  ID=$(date +%s%N)

  docker run -d \
    --rm \
    --name "gha-runner-$ID" \
    -e RUNNER_NAME="runner-$ID" \
    -e RUNNER_TOKEN="$REG_TOKEN" \
    -e RUNNER_ALLOW_RUNASROOT=1 \
    -e ORG_URL="https://github.com/$ORG" \
    -v /var/run/docker.sock:/var/run/docker.sock \
    ghcr.io/actions/actions-runner:latest \
    ./config.sh --url https://github.com/$ORG --token $REG_TOKEN --unattended --ephemeral --replace && \
    ./run.sh

done