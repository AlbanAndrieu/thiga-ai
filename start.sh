#!/usr/bin/env bash
# shellcheck shell=bash

set -euo pipefail

WORKING_DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"

# shellcheck source=/dev/null
source "${WORKING_DIR}/scripts/step-0-color.sh"

mise install

./stop.sh

echo -e "${green} Start services ${NC}"

# Uncomment to install Nvidia GPU drivers
./scripts/run-nvidia-docker.sh || true

echo -e "${magenta} Ollama is running at http://localhost:30068/ ${NC}"
echo -e "${magenta} OpenWebUI is running at http://localhost:31028/ ${NC}"
echo -e "${magenta} LiteLLM is running at http://localhost:4000/ ${NC}"
echo -e "${magenta} LangFuse http://localhost:3000/auth/sign-in ${NC}"

echo -e "${cyan} docker compose --env-file .env up --force-recreate ${NC}"

docker compose --env-file .env up

exit 0
