#!/bin/bash
set -euo pipefail

# ---- Config (change if you like) ----
IMAGE_TAG="${IMAGE_TAG:-pxl_noetic_full_desktop_tigervnc:latest}"
USER_NAME="${USER_NAME:-user}"
USER_ID="${USER_ID:-1000}"     # fixed ids as requested
GROUP_ID="${GROUP_ID:-1000}"   # fixed ids as requested

# VirtualGL .deb we install is amd64; keep ARCH=amd64 inside the image
VGL_ARCH="amd64"

# ---- Host arch & platform handling (macOS on Apple Silicon => build amd64) ----
HOST_ARCH="$(uname -m)"
PLATFORM_ARGS=()
if [[ "$HOST_ARCH" == "arm64" || "$HOST_ARCH" == "aarch64" ]]; then
  # Build an x86_64 image even on ARM hosts (Docker Desktop uses buildx under the hood)
  PLATFORM_ARGS+=(--platform=linux/amd64)
fi

# ---- Build args passed to Dockerfile ----
BUILD_ARGS=(
  --build-arg "USER_NAME=${USER_NAME}"
  --build-arg "USER_ID=${USER_ID}"
  --build-arg "GROUP_ID=${GROUP_ID}"
  --build-arg "ARCH=${VGL_ARCH}"
)

# ---- Choose build command (buildx is more robust for cross-arch) ----
if docker buildx version >/dev/null 2>&1; then
  # Use buildx and load into local Docker (so you can run it right away)
  CMD=(docker buildx build --load "${PLATFORM_ARGS[@]}" -t "$IMAGE_TAG" "${BUILD_ARGS[@]}" .)
else
  # Fallback to classic docker build
  CMD=(docker build "${PLATFORM_ARGS[@]}" -t "$IMAGE_TAG" "${BUILD_ARGS[@]}" .)
fi

echo "Running: ${CMD[*]}"
"${CMD[@]}"
