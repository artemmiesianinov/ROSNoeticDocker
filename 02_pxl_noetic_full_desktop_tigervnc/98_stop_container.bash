#!/bin/bash
set -euo pipefail

NAME="${NAME:-pxl_noetic_tigervnc}"

if docker ps -a --format '{{.Names}}' | grep -q "^${NAME}\$"; then
  echo "Stopping container: ${NAME}"
  docker stop "${NAME}"
else
  echo "No container named '${NAME}' is running."
fi
