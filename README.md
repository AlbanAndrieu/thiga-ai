# thiga-ai

Stack IA Open source for thiga

# Initial Setup

```bash
git submodule add -f git@github.com:AlbanAndrieu/langfuse.git

git pull origin master --allow-unrelated-histories
git pull && git submodule init && git submodule update && git submodule status

# Important to have a tool to install all prerequisite such as docker compose and load env variables
mise install
# OR
source .env
```

# Start stack

Stop services that might conflict ports

```
sudo service redis stop # 6379
docker stop redis
sudo service postgresql stop # port 5432
docker stop postgres

sudo service netdata stop
```

```bash
sops -d secrets.env.sops > langfuse/.env.test
# mv langfuse/.env.test .env

# Check env are proerly loaded
# docker compose config

docker compose --env-file .env up
```

# Services availables :

[langfuse web](http://localhost:3000/)

Use sign up link

[clickhouse web](http://localhost:8123/)

# Security Considerations

## Add Firewall :

* I am using Cloudflared

* We Should to restrict inbound traffic on the host to langfuse-web (port 3000) and minio (port 9090) only.
* Then restrict all backend services behind a firewall for admin, only openwebui should be accessible for people allowed
* Later we could create iDp such as Keycloak, but right now Cloudflare tunnel with email address is enough

### Add Password maanger

Use Vault for password storage, and SSL protection instead of sops.
Using Vault will allow you to be independant of any Cloud provider and will ease transition to a real providuction Orchestrator such as kubernetes

### Quick password encryption

Cypher and un Cypher .env, [sops](https://blog.stephane-robert.info/docs/securiser/secrets/sops/) can later be integrated in Vault, Cloud KMS

#### Create a Thiga key

age-keygen -o thiga-ai.agekey

Give thiga-ai.agekey key to team member using preferally bitwarden send feature

#### Cypher
cp .env secrets.env.sops
sops -e -i secrets.env.sops

#### Uncypher
sops -d secrets.env.sops > .env.test

## Postgres database is not starting

docker compose exec postgres psql -U postgres -d postgres -c '\du'

## Use GPU

If you are on ubuntu, add nvidia toolkit to allow GPU in docker; See script scripts/run-nvidia-docker.sh and add gpus: all in docker-compose.yml

# Use model

[qwen3.5](https://ollama.com/library/qwen3.5)

```bash
export DEFAULT_MODELS="qwen3.5:2b"
```

# Ask you question OpenWebUI

Who is Alban ?

Answer without RAG Give :

There are several notable individuals named Alban, so it's possible that you're referring to one of the following:

Alban (Greek mythology): In Greek mythology, Alban was a hero who accompanied Jason on his quest for the Golden Fleece. He was said to be the son of King Iolcos and the brother of King Polydectes.
Alban I (King of Albania): Alban I was an ancient king of Albania, believed to have ruled from around 850 BCE to 800 BCE. His reign is not well documented, but he is considered one of the earliest known kings of Albania.
Alban Bairamaj: Alban Bairamaj is a Kosovo-born Albanian politician and diplomat who served as the Prime Minister of Kosovo from February 2014 to December 2017.
Alban Arda (Gaelic poet): Alban Arda was an ancient Celtic poet who lived in what is now Scotland. He is mentioned in several medieval Scottish texts, including the Historia Brittonum and the Historia Regum Britanniae.
Without more context, it's difficult to determine which Alban you're referring to. If you could provide more information or clarify which Alban you're interested in learning more about, I'd be happy to try and help further!

They show that:

✅ Open WebUI is successfully calling Ollama.
✅ Ollama is using your RTX 2060.
✅ The model is fully loaded on the GPU.
✅ The inference request reached Ollama.

For example:

CUDA0 : NVIDIA GeForce RTX 2060
load_tensors: offloaded 29/29 layers to GPU
CUDA0 model buffer size = 1918 MiB
CUDA0 KV buffer size = 448 MiB

This means 100% of the model layers are running on the GPU, not on the CPU.
