#!/bin/bash
set -e

# 1. Kiem tra bien moi truong bat buoc
if [ -z "${AZP_URL}" ]; then
  echo 1>&2 "error: missing AZP_URL environment variable"
  exit 1
fi

if [ -z "${AZP_TOKEN_FILE}" ]; then
  if [ -z "${AZP_TOKEN}" ]; then
    echo 1>&2 "error: missing AZP_TOKEN environment variable"
    exit 1
  fi

  AZP_TOKEN_FILE="/azp/.token"
  echo -n "${AZP_TOKEN}" > "${AZP_TOKEN_FILE}"
fi

unset AZP_TOKEN

if [ -n "${AZP_WORK}" ]; then
  mkdir -p "${AZP_WORK}"
fi

# 2. Cho Docker Daemon (DinD sidecar) san sang
if [ -n "${DOCKER_HOST}" ]; then
  echo "Waiting for Docker daemon at ${DOCKER_HOST}..."
  while ! docker info >/dev/null 2>&1; do
    echo "Docker not ready yet, sleeping 2s..."
    sleep 2
  done
  echo "Docker daemon is ready!"
fi

# Tu dong don dep log chan doan va file tam dinh ky moi 1 tieng
(
  while true; do
    sleep 3600
    find /azp/_diag -type f -name "*.log" -mmin +120 -delete 2>/dev/null || true
    rm -rf /azp/_work/_temp/* 2>/dev/null || true
  done
) &

# 3. Ham don dep Agent khoi Pool khi Pod bi dung/xoa
cleanup() {
  trap "" EXIT

  if [ -e ./config.sh ]; then
    echo "Cleanup: Removing Azure Pipelines agent from pool..."
    ./config.sh remove --unattended --auth "PAT" --token "$(cat "${AZP_TOKEN_FILE}")" || true
  fi
}

trap "cleanup; exit 0" EXIT
trap "cleanup; exit 130" INT
trap "cleanup; exit 143" TERM

# 4. Lay phien ban Azure Pipelines Agent phu hop
export AGENT_ALLOW_RUNASROOT="1"
export VSO_AGENT_IGNORE="AZP_TOKEN,AZP_TOKEN_FILE"
TARGETARCH="${TARGETARCH:-linux-x64}"

echo "1. Determining matching Azure Pipelines agent package for ${TARGETARCH}..."

AZP_AGENT_PACKAGES=$(curl -LsS \
    -u "user:$(cat "${AZP_TOKEN_FILE}")" \
    -H "Accept:application/json;" \
    "${AZP_URL}/_apis/distributedtask/packages/agent?platform=${TARGETARCH}&top=1")

AZP_AGENT_PACKAGE_LATEST_URL=$(echo "${AZP_AGENT_PACKAGES}" | jq -r ".value[0].downloadUrl")

if [ -z "${AZP_AGENT_PACKAGE_LATEST_URL}" ] || [ "${AZP_AGENT_PACKAGE_LATEST_URL}" == "null" ]; then
  echo 1>&2 "error: could not determine a matching Azure Pipelines agent"
  echo 1>&2 "check that AZP_URL is correct and PAT token has Agent Pools (read, manage) permission"
  exit 1
fi

# 5. Tai va giai nen Agent
echo "2. Downloading and extracting Azure Pipelines agent..."
curl -LsS "${AZP_AGENT_PACKAGE_LATEST_URL}" | tar -xz & wait $!

source ./env.sh

# 6. Cau hinh Agent vao Azure DevOps Pool
echo "3. Configuring Azure Pipelines agent..."
./config.sh --unattended \
  --agent "${AZP_AGENT_NAME:-$(hostname)}" \
  --url "${AZP_URL}" \
  --auth "PAT" \
  --token "$(cat "${AZP_TOKEN_FILE}")" \
  --pool "${AZP_POOL:-Default}" \
  --work "${AZP_WORK:-_work}" \
  --replace \
  --acceptTeeEula & wait $!

# 7. Chay Agent
echo "4. Running Azure Pipelines agent..."
chmod +x ./run.sh
./run.sh "$@" & wait $!

