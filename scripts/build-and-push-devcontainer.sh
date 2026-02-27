#!/usr/bin/env bash
set -euo pipefail

# === Configuration ===
IMAGE_NAME="nagasakah/web-design"
PLATFORM="linux/amd64"
NO_PUSH=false

# === Functions ===
usage() {
  cat <<EOF
Usage: $(basename "$0") [OPTIONS]

Build and push devcontainer pre-built images (2-stage build).

Options:
  --no-push            Build only, skip pushing images
  --platform <platform> Target platform (default: linux/amd64)
  --help               Show this help message
EOF
  exit 0
}

# === Argument Parsing ===
while [[ $# -gt 0 ]]; do
  case "$1" in
    --no-push)
      NO_PUSH=true
      shift
      ;;
    --platform)
      PLATFORM="${2:?Error: --platform requires a value}"
      shift 2
      ;;
    --help)
      usage
      ;;
    *)
      echo "Error: Unknown option: $1" >&2
      usage
      ;;
  esac
done

# === Step 1: Build base image ===
echo "Step 1: Building base image with devcontainer CLI..."
devcontainer build \
  --workspace-folder . \
  --image-name "${IMAGE_NAME}:base" \
  --platform "${PLATFORM}"
echo "Step 1: Done."

# === Step 2: Build latest image ===
echo "Step 2: Building latest image with docker buildx..."
docker buildx build \
  --platform "${PLATFORM}" \
  -t "${IMAGE_NAME}:latest" \
  -f .devcontainer/Dockerfile \
  .devcontainer/ \
  --load
echo "Step 2: Done."

# === Push ===
if [[ "${NO_PUSH}" == "false" ]]; then
  echo "Pushing images..."
  docker push "${IMAGE_NAME}:base"
  docker push "${IMAGE_NAME}:latest"
  echo "Push complete."
else
  echo "Skipping push (--no-push specified)."
fi

echo "All steps completed successfully."
