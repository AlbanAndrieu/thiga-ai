#!/usr/bin/env bash
set -euo pipefail
curl -fsSL https://nvidia.github.io/libnvidia-container/gpgkey|sudo gpg --dearmor -o /usr/share/keyrings/nvidia-container-toolkit-keyring.gpg
curl -s -L https://nvidia.github.io/libnvidia-container/stable/deb/nvidia-container-toolkit.list|sed 's#deb https://#deb [signed-by=/usr/share/keyrings/nvidia-container-toolkit-keyring.gpg] https://#g'|sudo tee /etc/apt/sources.list.d/nvidia-container-toolkit.list
sudo apt-get update&&  sudo apt-get install -y nvidia-container-toolkit
sudo nvidia-ctk runtime configure --runtime=docker
sudo systemctl restart docker
nvidia-smi
docker run --gpus all nvcr.io/nvidia/cuda:12.4.1-base-ubuntu22.04 nvidia-smi
sudo journalctl -n -u nvidia-docker
nvidia-container-cli -k -d /dev/tty info
exit 0
