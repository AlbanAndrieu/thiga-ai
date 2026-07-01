#!/usr/bin/env bash
# shellcheck shell=bash

set -euo pipefail

WORKING_DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"

# shellcheck source=/dev/null
source "${WORKING_DIR}/scripts/step-0-color.sh"

echo -e "${green} Initialize stack ${NC}"

export DEFAULT_MODELS="qwen3:4b" # qwen3.5:2b llama3.2
export OLLAMA_PORT=${OLLAMA_PORT:-11434}

curl http://localhost:${OLLAMA_PORT}/api/pull \
  -d '{
    "name": "qwen3:4b"
  }'

docker exec ollama ollama pull nomic-embed-text

echo -e "${magenta} Bootstrap knowledge base ${NC}"

${WORKING_DIR}/scripts/openwebui-bootstrap-thiga.sh

echo -e "${magenta} Bootstrap langfuse scoring ${NC}"

pip3 install langfuse requests python-dotenv
python3 scripts/langfuse-score-openwebui-sessions.py

exit 0
