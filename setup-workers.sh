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

# Ensure storage directories exist on host
echo "Creating storage directories..."
mkdir -p /mnt/storage/iot-agent/docker-local
mkdir -p /mnt/storage/iot-agent/helm-charts

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
    --name "gha-runner-$ID" \
    --network host \
    -e RUNNER_NAME="runner-$ID" \
    -e RUNNER_TOKEN="$REG_TOKEN" \
    -e RUNNER_SCOPE="org" \
    -e ORG_NAME="$ORG" \
    -e LABELS="self-hosted,iot-agent-local" \
    -e DISABLE_AUTO_UPDATE=1 \
    -v /var/run/docker.sock:/var/run/docker.sock \
    -v /run/k3s:/run/k3s \
    -v /etc/rancher/k3s:/etc/rancher/k3s:ro \
    -v /mnt/storage/iot-agent:/mnt/storage/iot-agent \
    --restart always \
    my-gha-runner:java

done