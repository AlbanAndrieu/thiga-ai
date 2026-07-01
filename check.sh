#!/bin/bash
set -xv

docker compose --env-file .env config | grep -A20 LANGFUSE_INIT

# docker exec -it ollama ollama pull llama3.2

# TODO : protect API endpoint

export DEFAULT_MODELS="qwen3.5:2b" # llama3.2

curl http://localhost:30068/api/pull \
	-d '{
    "name": "${DEFAULT_MODELS}"
  }'

docker exec -it ollama ollama list

# Open WebUI:

# Admin Panel → Settings → Connections → Ollama
# http://localhost:31028/admin/settings/connections

curl http://localhost:30068/api/tags

docker exec -it open-webui python -c "
import urllib.request
print(urllib.request.urlopen('http://ollama:30068/api/tags').read().decode())
"

curl http://localhost:4000/v1/chat/completions \
	-H "Authorization: Bearer ${LITELLM_MASTER_KEY}" \
	-H "Content-Type: application/json" \
	-d '{
    "model": "${DEFAULT_MODELS}",
    "messages": [{"role": "user", "content": "Who is Alban?"}]
  }'

exit 0
