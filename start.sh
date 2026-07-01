#!/usr/bin/env bash
# shellcheck shell=bash

set -euo pipefail

WORKING_DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"

# shellcheck source=/dev/null
source "${WORKING_DIR}/scripts/step-0-color.sh"

./stop.sh

echo -e "${green} Start services ${NC}"

# Uncomment to install Nvidia GPU drivers
# ./scripts/run-nvidia-docker.sh

echo -e "${magenta} Ollama is running at http://localhost:30068/ ${NC}"
echo -e "${magenta} OpenWebUI is running at http://localhost:31028/ ${NC}"
echo -e "${magenta} LiteLLM is running at http://localhost:4000/ ${NC}"
echo -e "${magenta} LangFuse http://localhost:3000/auth/sign-in ${NC}"

# Pipeline http://0.0.0.0:9099
# Minio API: http://172.16.2.2:9000  http://127.0.0.1:9000
# Minio WebUI: http://172.16.2.2:9001 http://127.0.0.1:9001
# PostgreSQL 5432
# Redis 6379
# ClickHouse 8123
# ClickHouse 9000

docker compose --env-file .env up --force-recreate

exit 0
