#!/usr/bin/env bash
# shellcheck shell=bash

set -euo pipefail

WORKING_DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"

echo "WORKING_DIR: ${WORKING_DIR}"

# shellcheck source=/dev/null
source "${WORKING_DIR}/scripts/step-0-color.sh"

echo -e "${green} Stop running service ${NC}"

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
echo -e "PROJECT_NAME is ${PROJECT_NAME} ${NC}"

echo -e "${cyan} docker volume rm ${PROJECT_NAME}_langfuse_clickhouse_data ${NC}"
echo -e "${cyan} docker volume rm ${PROJECT_NAME}_langfuse_clickhouse_logs ${NC}"
echo -e "${cyan} docker volume rm ${PROJECT_NAME}_langfuse_minio_data ${NC}"
echo -e "${cyan} docker volume rm ${PROJECT_NAME}_langfuse_postgres_data ${NC}"
echo -e "${cyan} docker volume rm ${PROJECT_NAME}_langfuse_redis_data ${NC}"
echo -e "${cyan} docker volume rm ${PROJECT_NAME}_ollama ${NC}"
echo -e "${cyan} docker volume rm ${PROJECT_NAME}_open-webui ${NC}"
echo -e "${cyan} docker volume rm ${PROJECT_NAME}_pipelines ${NC}"

docker volume list

exit 0
