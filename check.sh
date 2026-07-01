#!/bin/bash
set -xv

docker compose --env-file .env config | grep -A20 LANGFUSE_INIT

echo -e "${green} Ollama ${NC}"

export DEFAULT_MODELS="qwen3:4b" # qwen3.5:2b llama3.2
export OLLAMA_PORT=${OLLAMA_PORT:-11434}

curl http://localhost:${OLLAMA_PORT}/api/pull \
  -d '{
    "name": "qwen3:4b"
  }'

docker exec -it ollama ollama pull ${DEFAULT_MODELS}

docker exec -it ollama ollama list

# Open WebUI:
echo -e "${green} Check Open WebUI ${NC}"

# Admin Panel → Settings → Connections → Ollama
# http://localhost:31028/admin/settings/connections

curl http://localhost:${OLLAMA_PORT}/api/tags

docker exec -it open-webui python -c "
import urllib.request
print(urllib.request.urlopen('http://ollama:${OLLAMA_PORT}/api/tags').read().decode())
"
docker exec open-webui env | grep DEFAULT

docker exec open-webui printenv OPENAI_API_KEY

echo -e "${green} Check LiteLLM ${NC}"

curl http://localhost:4000/v1/models \
  -H "Authorization: Bearer $LITELLM_MASTER_KEY" | jq

curl http://localhost:4000/v1/chat/completions \
  -H "Authorization: Bearer ${LITELLM_MASTER_KEY}" \
  -H "Content-Type: application/json" \
  -d '{
    "model": "${DEFAULT_MODELS}",
    "messages": [{"role": "user", "content": "Who is Alban?"}]
  }'

echo -e "${green} Check Langfuse ${NC}"

# Check langfuse
curl -i http://localhost:3000/api/public/health

# docker compose --env-file .env up -d --force-recreate langfuse-web langfuse-worker

curl http://localhost:4000/v1/chat/completions \
  -H "Authorization: Bearer $LITELLM_MASTER_KEY" \
  -H "Content-Type: application/json" \
  -d '{
    "model": "qwen",
    "messages": [{"role": "user", "content": "Say hello and trace this request"}],
    "stream": false
  }'

# test minio from langfuse
docker exec thiga-ai-langfuse-web-1 sh -lc '
node -e "console.log(process.env.LANGFUSE_S3_EVENT_UPLOAD_ACCESS_KEY_ID, process.env.LANGFUSE_S3_EVENT_UPLOAD_SECRET_ACCESS_KEY, process.env.LANGFUSE_S3_EVENT_UPLOAD_ENDPOINT)"
'

exit 0
