#!/bin/bash
# set -xv

# Free port 6379
sudo service redis stop 2>/dev/null || true
docker stop redis 2>/dev/null || true

# Free port 5432
sudo service postgresql stop 2>/dev/null || true
docker stop postgres 2>/dev/null || true

# Free port 11434
sudo service ollama stop 2>/dev/null || true
docker stop ollama 2>/dev/null || true

# Free port 4000
sudo service litellm stop 2>/dev/null || true
docker stop litellm 2>/dev/null || true

sudo service netdata stop 2>/dev/null || true

docker compose --env-file .env down

export PROJECT_NAME=${PROJECT_NAME-thiga}
echo "PROJECT_NAME is ${PROJECT_NAME}"

echo "docker volume rm ${PROJECT_NAME}_langfuse_clickhouse_data"
echo "docker volume rm ${PROJECT_NAME}_langfuse_clickhouse_logs"
echo "docker volume rm ${PROJECT_NAME}_langfuse_minio_data"
echo "docker volume rm ${PROJECT_NAME}_langfuse_postgres_data"
echo "docker volume rm ${PROJECT_NAME}_langfuse_redis_data"
echo "docker volume rm ${PROJECT_NAME}_ollama"
echo "docker volume rm ${PROJECT_NAME}_open-webui"
echo "docker volume rm ${PROJECT_NAME}_pipelines"

docker volume list

exit 0
