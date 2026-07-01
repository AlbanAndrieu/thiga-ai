# Troubleshooting & Lessons Learned

This document summarizes the main issues encountered while building the sovereign AI stack based on Open WebUI, LiteLLM, Ollama and Langfuse.

The goal is not only to document fixes, but also to show the reasoning process behind the architecture and the production risks discovered during implementation.

---

## 1. LiteLLM `/metrics` authentication issue

### Symptom

Prometheus scraping failed with:

```text
Malformed API Key passed in. Ensure Key has `Bearer ` prefix.
GET /metrics HTTP/1.1" 401 Unauthorized
```

### Root cause

LiteLLM expects an Authorization header using the `Bearer` scheme. Prometheus was either sending the wrong value or the wrong secret.

### Fix

Use a Docker secret and configure Prometheus with:

```yaml
authorization:
  type: Bearer
  credentials_file: /run/secrets/litellm_api_key
```

The file must contain only the raw key, for example:

```text
sk-...
```

not:

```text
Bearer sk-...
```

### Lesson learned

Secrets must be checked inside the container, not only on the host.

---

## 2. SOPS dotenv encryption issue

### Symptom

Decrypting a SOPS-encrypted `.env` failed with:

```text
Error unmarshalling input json: invalid character '#' looking for beginning of value
```

### Root cause

SOPS tried to parse the file as JSON/YAML instead of dotenv.

### Fix

Use explicit input/output types:

```bash
sops encrypt --age "$AGE_PUBLIC_KEY_NABLA" \
  --input-type dotenv \
  --output-type dotenv \
  langfuse/.env > secrets.env.sops

sops decrypt \
  --input-type dotenv \
  --output-type dotenv \
  secrets.env.sops > langfuse/.env.test
```

### Lesson learned

Dotenv files with `#`, `%`, `$`, `&` and quotes must be handled carefully.

---

## 3. Docker Compose `.env` not loaded through `include`

### Symptom

Environment variables were not applied correctly when using:

```yaml
include:
  - path: langfuse/docker-compose.yml
```

### Root cause

Docker Compose `include` does not automatically merge service-level environment overrides the way expected. Importing several Compose fragments can also create resource conflicts.

### Fix

Use:

```bash
docker compose --env-file .env config
```

to verify final resolved configuration before starting.

### Lesson learned

Always inspect the final Compose rendering.

---

## 4. Docker networking: `localhost` vs service name

### Symptom

Langfuse or LiteLLM failed to connect to Postgres/Redis/Ollama using `localhost`.

### Root cause

Inside a Docker container, `localhost` means the container itself, not the host and not another service.

### Fix

Use Docker service names:

```env
DATABASE_URL=postgresql://postgres:password@postgres:5432/postgres
REDIS_HOST=redis
OLLAMA_BASE_URL=http://ollama:11434
OPENAI_API_BASE_URL=http://litellm:4000/v1
```

### Lesson learned

Use `localhost` only from the host machine. Use service DNS names inside Docker networks.

---

## 5. Ollama GPU not available

### Symptom

Docker failed with:

```text
could not select device driver "nvidia" with capabilities: [[gpu]]
```

### Root cause

The NVIDIA container runtime/toolkit was missing or not configured.

### Fix

Install NVIDIA Container Toolkit and use:

```yaml
services:
  ollama:
    gpus: all
```

### Verification

Ollama logs should show:

```text
CUDA0 : NVIDIA GeForce RTX 2060
offloaded layers to GPU
```

### Lesson learned

GPU availability must be verified from inside the container logs.

---

## 6. Ollama warmup command confusion

### Symptom

The `ollama-init` container generated a full answer to the word `warmup`.

### Root cause

`warmup` is not an Ollama command. It was interpreted as a prompt.

### Fix

Use a very short generation request:

```bash
curl -s http://ollama:11434/api/generate \
  -H "Content-Type: application/json" \
  -d '{
    "model": "qwen3:4b",
    "prompt": "ping",
    "stream": false,
    "options": {"num_predict": 1}
  }' >/dev/null
```

### Lesson learned

Warmup means “trigger one minimal inference”, not “run a warmup command”.

---

## 7. Open WebUI accidentally bypassing LiteLLM

### Symptom

Langfuse received no traces.

### Root cause

Open WebUI was still calling Ollama directly or `OPENAI_API_BASE_URL` was defined twice. The second value overwrote the LiteLLM endpoint.

### Fix

Use only:

```yaml
environment:
  ENABLE_OLLAMA_API: "false"
  ENABLE_OPENAI_API: "true"
  OPENAI_API_BASE_URL: http://litellm:4000/v1
  OPENAI_API_KEY: ${LITELLM_MASTER_KEY}
```

Remove duplicate values such as:

```yaml
OPENAI_API_BASE_URL=http://pipelines:9099
```

### Verification

LiteLLM logs must show:

```text
POST /v1/chat/completions
```

### Lesson learned

If Langfuse is empty, first verify the request path: Open WebUI → LiteLLM → Ollama.

---

## 8. LiteLLM Admin UI and stateless mode

### Symptom

LiteLLM Admin UI login failed with:

```text
Authentication Error, Not connected to DB!
```

### Root cause

LiteLLM Admin UI requires a database. Stateless mode works for API proxying, but not for the Admin UI.

### Options

#### Stateless mode

Use only `config.yaml` and `LITELLM_MASTER_KEY`.

#### Admin UI mode

Enable PostgreSQL and run migrations.

### Lesson learned

For the technical assessment, LiteLLM can remain mostly stateless unless Admin UI features are required.

---

## 9. LiteLLM database migrations and model token mismatch

### Symptom

LiteLLM rejected a token with:

```text
Invalid proxy server token passed ... not found in db
```

### Root cause

When `store_model_in_db: true` is enabled, LiteLLM checks keys in the database. Open WebUI may hold an old or invalid API key.

### Fix

Either:

1. use the master key consistently;
2. or create a LiteLLM DB key via `/key/generate`.

### Lesson learned

When LiteLLM is database-backed, API keys become stateful.

---

## 10. LiteLLM migration resolver warning

### Symptom

LiteLLM displayed:

```text
Using default (v1) migration resolver...
try --use_v2_migration_resolver
```

### Observation

The v2 resolver was considered, but it produced additional errors during testing.

### Decision

Keep the default resolver temporarily because the stack started correctly without it.

### Lesson learned

Migration optimizations should not be enabled blindly during an assessment. Prefer stability over theoretical improvement.

---

## 11. Langfuse traces received but not visible due to MinIO/S3 signature errors

### Symptom

Langfuse failed with:

```text
SignatureDoesNotMatch
Failed to upload JSON to S3 events/otel/...
```

### Root cause

MinIO credentials and Langfuse S3 credentials did not match, or MinIO retained old credentials in an existing volume.

### Fix

Align all values:

```env
MINIO_ROOT_USER=minio
MINIO_ROOT_PASSWORD=miniosecret

LANGFUSE_S3_EVENT_UPLOAD_ACCESS_KEY_ID=minio
LANGFUSE_S3_EVENT_UPLOAD_SECRET_ACCESS_KEY=miniosecret
LANGFUSE_S3_EVENT_UPLOAD_ENDPOINT=http://minio:9000
LANGFUSE_S3_EVENT_UPLOAD_FORCE_PATH_STYLE=true
```

Then recreate the MinIO volume if credentials changed:

```bash
docker compose down
docker volume rm thiga-ai_langfuse_minio_data
docker compose --env-file .env up -d minio langfuse-web langfuse-worker
```

### Lesson learned

Changing MinIO root credentials does not update an existing MinIO data volume.

---

## 12. MinIO vs ClickHouse port confusion

### Symptom

Opening `http://localhost:9000` showed ClickHouse, not MinIO.

### Root cause

Port `9000` on the host was mapped to ClickHouse native protocol. MinIO was only reachable inside Docker at `http://minio:9000`.

### Fix

Use the host-mapped MinIO ports:

```text
MinIO API:     http://localhost:9090
MinIO Console: http://localhost:9091
```

Internally, Langfuse should still use:

```text
http://minio:9000
```

### Lesson learned

Internal container ports and host-published ports are different concerns.

---

## 13. Langfuse batch export not enabled

### Symptom

Langfuse worker failed with:

```text
Batch export is not enabled.
Configure environment variables to use this feature.
```

### Root cause

Tracing worked, but batch export requires separate S3 variables.

### Fix

Add to both `langfuse-web` and `langfuse-worker`:

```env
LANGFUSE_S3_BATCH_EXPORT_ENABLED=true
LANGFUSE_S3_BATCH_EXPORT_BUCKET=langfuse
LANGFUSE_S3_BATCH_EXPORT_PREFIX=exports/
LANGFUSE_S3_BATCH_EXPORT_REGION=us-east-1
LANGFUSE_S3_BATCH_EXPORT_ENDPOINT=http://minio:9000
LANGFUSE_S3_BATCH_EXPORT_ACCESS_KEY_ID=minio
LANGFUSE_S3_BATCH_EXPORT_SECRET_ACCESS_KEY=miniosecret
LANGFUSE_S3_BATCH_EXPORT_FORCE_PATH_STYLE=true
```

### Lesson learned

Langfuse event upload, media upload and batch export are three distinct S3 configurations.

---

## 14. ClickHouse 26.x incompatible with Langfuse scores

### Symptom

After adding scores, Langfuse UI failed on `scores.all` with:

```text
Not found column and(equals(...))
ClickHouse query failed
```

### Root cause

ClickHouse 26.x changed query analysis behavior and Langfuse scores queries failed.

### Fix

Pin ClickHouse to a known compatible LTS version:

```env
CLICKHOUSE_VERSION=25.8
```

or:

```yaml
clickhouse:
  image: clickhouse/clickhouse-server:25.8
```

If local data can be lost:

```bash
docker compose down
docker volume rm thiga-ai_langfuse_clickhouse_data thiga-ai_langfuse_clickhouse_logs
docker compose --env-file .env up -d clickhouse langfuse-web langfuse-worker
```

### Lesson learned

Do not use `latest` for infrastructure databases in a demo or assessment.

---

## 15. Open WebUI API schema unavailable

### Symptom

`/openapi.json` returned HTML instead of JSON.

### Root cause

Open WebUI only exposes OpenAPI in development mode.

### Fix

Use:

```yaml
environment:
  ENV: dev
```

or:

```yaml
- ENV=dev
```

Avoid:

```yaml
- ENV="dev"
```

### Lesson learned

For automation and reverse engineering, enabling OpenAPI is very useful.

---

## 16. Automating Open WebUI assistant and Knowledge Base creation

### Problems faced

Several issues occurred:

- duplicated Knowledge Bases;
- assistant created but not attached to Knowledge;
- model ID already registered;
- delete endpoint mismatch;
- `meta.knowledge` schema was not obvious;
- OpenAPI schema had to be inspected;
- the assistant initially answered as if it had no CV or job description.

### Root cause

Open WebUI v0.10.2 expects the assistant `meta.knowledge` field to contain enriched file objects, not only the Knowledge Base ID.

### Working format

The assistant must receive objects similar to:

```json
{
  "id": "file-id",
  "type": "file",
  "name": "filename.pdf",
  "meta": {
    "collection_name": "vector-collection-name"
  },
  "collection": {
    "id": "knowledge-base-id",
    "name": "Knowledge Base Name"
  }
}
```

### Lesson learned

The visible “Knowledge Base” in the UI and the actual vector collection are not exactly the same object.

---

## 17. Vector search validation

### Symptom

The assistant showed attached files but did not use RAG correctly.

### Debugging step

Direct vector search was tested with:

```bash
curl -s -X POST "$OPEN_WEBUI_URL/api/v1/retrieval/query/collection" \
  -H "Authorization: Bearer $OPEN_WEBUI_TOKEN" \
  -H "Content-Type: application/json" \
  -d '{
    "collection_names": ["<collection_name>"],
    "query": "Solution Architect Cloud DevSecOps Kubernetes GenAI Alban Andrieu",
    "k": 5
  }'
```

### Result

The API returned chunks from both:

- the CV;
- the Thiga Solution Architect job description.

### Lesson learned

Always test the vector store independently before debugging the assistant prompt.

---

## 18. Open WebUI prompt behavior

### Symptom

The assistant answered:

```text
I don't have access to CV analysis tools...
```

### Root cause

The model interpreted the task as requiring tools instead of using the attached Knowledge context.

### Fix

Disable unnecessary assistant capabilities:

```json
"capabilities": {
  "file_context": true,
  "citations": true,
  "vision": false,
  "file_upload": false,
  "web_search": false,
  "image_generation": false,
  "code_interpreter": false,
  "terminal": false,
  "builtin_tools": false
}
```

Use a stronger system prompt:

```text
You do not need external tools. Use the attached Knowledge files only.
Never answer that you lack CV analysis tools.
```

### Lesson learned

For local models, explicit negative instructions are often required to avoid tool-related refusals.

---

## 19. Embedding model behavior

### Observation

Open WebUI used embeddings through the configured embedding endpoint:

```text
embedding_config = {'engine': 'openai', 'model': 'embedding'}
```

Earlier logs also showed local sentence-transformers loading:

```text
sentence-transformers/all-MiniLM-L6-v2
```

### Lesson learned

Open WebUI can embed documents either through its local embedding engine or an OpenAI-compatible endpoint. The selected embedding configuration must be verified from vector search metadata.

---

## 20. Langfuse user/session enrichment

### Result

After enabling header forwarding:

```yaml
ENABLE_FORWARD_USER_INFO_HEADERS=true
```

and LiteLLM header forwarding:

```yaml
custom_headers:
  forward_headers:
    - X-OpenWebUI-User-Name
    - X-OpenWebUI-User-Id
    - X-OpenWebUI-User-Email
    - X-OpenWebUI-User-Role
    - X-OpenWebUI-Chat-Id
    - X-Session-Id
    - X-OpenWebUI-Session
```

Langfuse sessions started showing the user email.

### Lesson learned

Observability is significantly more useful when user, session, chat and assistant identifiers are propagated.

---

## 21. Session-level scoring automation

### Goal

Add Langfuse session-level scores such as:

- `openwebui_trace_coverage`
- `openwebui_token_depth`
- `cv_job_match_score`
- `answer_grounding_score`
- `rag_relevance_score`

### Issue encountered

The first Python script failed because `LANGFUSE_HOST` pointed to `http://localhost:3000`, while Langfuse was not exposed on that host port.

### Fix

Use the host-published port when running from the workstation:

```env
LANGFUSE_HOST=http://localhost:<published-port>
```

or the Docker service name when running from inside Docker:

```env
LANGFUSE_HOST=http://langfuse-web:3000
```

### Lesson learned

Automation scripts must distinguish host networking from Docker networking.

---

## 22. Python 3.14 compatibility warning

### Symptom

The Langfuse SDK produced:

```text
Core Pydantic V1 functionality isn't compatible with Python 3.14 or greater.
```

### Fix

Use Python 3.12 for automation:

```bash
mise use python@3.12
pip install -U langfuse requests python-dotenv
```

### Lesson learned

Use stable Python versions for SDK automation.

---

## 23. Remaining improvements

### Short term

- Pin all images instead of using `latest`.
- Add a documented `.env.example`.
- Add health checks.
- Add Makefile targets.
- Add backup/restore commands.
- Add smoke tests.
- Add Langfuse score automation.

### Medium term

- Keycloak/OIDC integration.
- Vault for secrets.
- AKS deployment.
- GitOps deployment.
- Network policies.
- Model benchmarking.
- LLM-as-a-Judge evaluations.

### Long term

- Multi-tenant assistant factory.
- Policy-based routing.
- PII redaction gateway.
- Prompt registry.
- Production-grade SLOs.

---

## Summary

Most issues were not caused by the core stack itself, but by integration boundaries:

- Docker networking;
- environment variable loading;
- Open WebUI internal API schema;
- Langfuse S3 configuration;
- ClickHouse version compatibility;
- LiteLLM stateful vs stateless behavior;
- assistant metadata schema;
- vector collection vs Knowledge Base abstraction.

The final platform is stronger because these issues forced production-relevant decisions: pinned infrastructure, explicit observability, documented failure modes, and repeatable bootstrap automation.
