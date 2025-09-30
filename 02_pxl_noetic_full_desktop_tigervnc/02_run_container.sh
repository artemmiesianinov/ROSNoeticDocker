#!/bin/bash
set -euo pipefail

# --- Configurable variables ---
IMAGE="${IMAGE:-pxl_noetic_full_desktop_tigervnc:latest}"
NAME="${NAME:-pxl_noetic_tigervnc}"
HOSTNAME="noetic"

# Default VNC password (can override with: VNC_PASSWORD=secret ./02_run_container.sh )
VNC_PASSWORD="${VNC_PASSWORD:-password}"


# --- Base options ---
DOCKER_OPTS=()
DOCKER_OPTS+=("--rm" "-d")                           # run detached, auto-clean
DOCKER_OPTS+=("--name=${NAME}")
DOCKER_OPTS+=("--hostname=${HOSTNAME}")
DOCKER_OPTS+=("-p" "5901:5901")
DOCKER_OPTS+=("-e" "TERM=xterm-256color")

# VNC/Display envs
DOCKER_OPTS+=("-e" "VNC_PASSWORD=${VNC_PASSWORD}")
DOCKER_OPTS+=("-e" "VNC_GEOMETRY=${VNC_GEOMETRY:-1920x1080}")

# Bind mounts (host -> container)
DOCKER_OPTS+=("-v" "$(pwd)/../Commands/bin:/home/user/bin")
DOCKER_OPTS+=("-v" "$(pwd)/../ExampleCode:/home/user/ExampleCode")
DOCKER_OPTS+=("-v" "$(pwd)/../Data:/home/user/Data")
DOCKER_OPTS+=("-v" "$(pwd)/../Projects/catkin_ws_src:/home/user/Projects/catkin_ws/src")

# Shared memory (some apps need more than default 64MB)
DOCKER_OPTS+=("--shm-size=1GB")

# --- Platform / GPU detection ---
ARCH="$(uname -m)"
if [[ "$ARCH" == "arm64" || "$ARCH" == "aarch64" ]]; then
  DOCKER_OPTS+=("--platform=linux/amd64")
fi

# NVIDIA path (Linux host with NVIDIA runtime)
if command -v nvidia-smi &>/dev/null; then
  if nvidia-smi &>/dev/null; then
    if docker info 2>/dev/null | grep -qE 'Runtimes:.*nvidia'; then
      echo "NVIDIA GPU and runtime detected -> enabling --gpus all"
      DOCKER_OPTS+=("--gpus" "all")
    else
      echo "NVIDIA detected but Docker NVIDIA runtime missing; skipping --gpus all."
    fi
  else
    echo "nvidia-smi present but not usable; skipping --gpus all."
  fi
fi

# Intel/AMD path (Linux with DRM). Only add when /dev/dri exists.
if [[ -e /dev/dri ]]; then
  DOCKER_OPTS+=("--device=/dev/dri:/dev/dri")
fi

# Image (don’t add 'bash' — keep image CMD to launch VNC)
DOCKER_OPTS+=("${IMAGE}")

echo "Docker command: docker run ${DOCKER_OPTS[*]}"
docker run "${DOCKER_OPTS[@]}"

echo "→ VNC is starting. Connect your VNC client to localhost:5901 (password: ${VNC_PASSWORD})"
