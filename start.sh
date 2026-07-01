#!/bin/bash
# set -xv

./stop.sh

# Uncomment to install Nvidia GPU drivers
# ./scripts/run-nvidia-docker.sh

docker compose --env-file .env up

echo "Ollama is running at http://localhost:30068/"
echo "OpenWebUI is running at http://localhost:31028/"

exit 0
