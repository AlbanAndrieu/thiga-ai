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

# Warm up model
curl -s http://ollama:11434/api/generate \
  -H "Content-Type: application/json" \
  -d "{\"model\":\"qwen3:4b\",\"prompt\":\"ping\",\"stream\":false,\"options\":{\"num_predict\":1}}" \
  >/dev/null

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

curl -H "Authorization: Bearer ${OPEN_WEBUI_API_KEY}" \
  http://localhost:31028/api/models

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

echo "http://localhost:31028/workspace/models/edit?id=assistant-thiga-solution-architect"

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

# Fix bug in clickouse for scoring, down grade
docker exec thiga-ai-clickhouse-1 clickhouse-client --query "SELECT version()"
# 26.6.1.1193

# Check assistant

curl -i "$OPEN_WEBUI_URL/openapi.json" \
  -H "Accept: application/json"

curl -s "$OPEN_WEBUI_URL/api/v1/knowledge/" \
  -H "Authorization: Bearer $OPEN_WEBUI_TOKEN" | jq

curl -s "$OPEN_WEBUI_URL/api/models" \
  -H "Authorization: Bearer $OPEN_WEBUI_TOKEN" | jq

curl -s "$OPEN_WEBUI_URL/api/v1/models/base" \
  -H "Authorization: Bearer $OPEN_WEBUI_TOKEN" | jq

curl -s "$OPEN_WEBUI_URL/api/v1/models/model/assistant-thiga-solution-architect" \
  -H "Authorization: Bearer $OPEN_WEBUI_TOKEN" | jq

# Check Knowledge Graph

KB_ID="$(
  curl -s "$OPEN_WEBUI_URL/api/v1/knowledge/" \
    -H "Authorization: Bearer $OPEN_WEBUI_TOKEN" |
    jq -r '.items[] | select(.name=="CV and postion matcher For Thiga") | .id'
)"

curl -s "$OPEN_WEBUI_URL/api/v1/knowledge/$KB_ID/files" \
  -H "Authorization: Bearer $OPEN_WEBUI_TOKEN" | jq

COLLECTION_NAME="$(
  curl -s "$OPEN_WEBUI_URL/api/v1/knowledge/$KB_ID/files" \
    -H "Authorization: Bearer $OPEN_WEBUI_TOKEN" |
    jq -r '.items[0].meta.collection_name'
)"

curl -s -X POST "$OPEN_WEBUI_URL/api/v1/retrieval/query/collection" \
  -H "Authorization: Bearer $OPEN_WEBUI_TOKEN" \
  -H "Content-Type: application/json" \
  -d "$(jq -n \
    --arg collection_name "$COLLECTION_NAME" \
    --arg query "Solution Architect Cloud DevSecOps Kubernetes GenAI Alban Andrieu" \
    '{
      collection_names: [$collection_name],
      query: $query,
      k: 5
    }')" | jq

curl -s "$OPEN_WEBUI_URL/openapi.json" \
  -H "Authorization: Bearer $OPEN_WEBUI_TOKEN" |
  jq '.components.schemas.QueryCollectionsForm'

exit 0
