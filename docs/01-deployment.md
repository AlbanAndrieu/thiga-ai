# Deployment

Init environement

```bash
git submodule add -f git@github.com:AlbanAndrieu/langfuse.git

git pull origin master --allow-unrelated-histories
git pull && git submodule init && git submodule update && git submodule status
```

Important to have a tool to install all prerequisite such as docker compose and load env variables

```bash
mise install
```

Give thiga-ai.agekey key to team member using preferally bitwarden send feature

Uncypher env variable

```bash
sops -d secrets.env.sops > .env

If no mise
source .env
```

# Initial Setup

Stop services that might conflict ports

```bash
./stop.sh

sudo service redis stop # 6379
docker stop redis
sudo service postgresql stop # port 5432
docker stop postgres
```

```bash
./stop.sh
./start.sh
```

Run the `init.sh` to create Assistant Thiga Solution Architect, but warning it seems to allow web search by default, so it might send PII info to outside world,
we should block such behavior, more globally with firwall or a squid proxy

```bash
./init.sh
```

The following services are exposed by the local Docker stack.

| Service | URL | Notes |
|---------|-----|------|
| **Open WebUI** | http://localhost:31028/ | Main AI chat interface |
| **Langfuse** | http://localhost:3000/ | LLM Observability, Tracing and Evaluation *(Create an account using **Sign Up** on first startup.)* |
| **LiteLLM** | http://localhost:4000/ | OpenAI-compatible LLM Gateway |


| Service | URL | Notes |
|---------|-----|------|
| **ClickHouse HTTP** | http://localhost:8123/ | ClickHouse HTTP endpoint |
| **ClickHouse Play** | http://localhost:8123/play | Interactive SQL playground |
| **ClickHouse Dashboard** | http://localhost:8123/dashboard | Built-in ClickHouse dashboard |
| **MinIO Console** | http://localhost:9090/ | S3 Object Storage Administration |
| **MinIO S3 API** | http://localhost:9000/ | S3-compatible endpoint used by Langfuse |
| **LiteLLM Swagger** | http://localhost:4000/docs | LiteLLM REST API documentation |
| **LiteLLM Health** | http://localhost:4000/health | Gateway health endpoint |
| **LiteLLM Models** | http://localhost:4000/v1/models | OpenAI-compatible models endpoint |
| **Ollama API** | http://localhost:11434/ | Local LLM inference server |
| **Ollama Tags** | http://localhost:11434/api/tags | Installed models |
| **Open WebUI API Docs** | http://localhost:31028/docs | FastAPI Swagger UI |
| **Open WebUI OpenAPI** | http://localhost:31028/openapi.json | OpenAPI specification |


## Use GPU

If you are on Ubuntu, add nvidia toolkit to allow GPU in docker; See script `scripts/run-nvidia-docker.sh` and add gpus: all in docker-compose.yml

# Use model

```bash
export DEFAULT_MODELS="qwen3:4b" # or change to qwen3.5:2b
```

qwen3:4b is a bit bigger and faster an my RTX

[qwen3](https://ollama.com/library/qwen3)
[qwen3.5](https://ollama.com/library/qwen3.5)

THe simplest, maybe to simple to have relevant outcome!

[llama3.2](https://ollama.com/library/llama3.2)

## Add API key for RAG

In case automatic API key generation is not working, do it by hand like :

Enable API key for Admin user [enable-api-key](https://docs.openwebui.com/features/authentication-access/api-keys/)

### Step 1: Enable API Keys Globally (Admin)

Log in as an administrator
Open Admin Panel > Settings > General
Scroll to the Authentication section
Toggle Enable API Keys on
Click Save

### Step 2: Generate a Key

Click your profile icon (bottom-left sidebar)
Select Settings > Account
In the API Keys section, click Generate New API Key
Give it a descriptive name (e.g., "Monitoring Bot")
Copy the key immediately - you won't be able to view it again
