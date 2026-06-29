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

#### Cypher
cp .env secrets.env.sops
sops -e -i secrets.env.sops

#### Uncypher
sops -d secrets.env.sops > .env.test

## Postgres database is not starting 

docker compose exec postgres psql -U postgres -d postgres -c '\du'
