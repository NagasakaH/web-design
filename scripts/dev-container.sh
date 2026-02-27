#!/usr/bin/env bash
set -euo pipefail

# ==============================================================================
# dev-container.sh - Development container management script (DooD/DinD)
# ==============================================================================

# Constants
PROJECT_NAME="web-design"
DEV_CONTAINER_IMAGE="${DEV_CONTAINER_IMAGE:-nagasakah/web-design:latest}"
DOCKER_MODE="${DOCKER_MODE:-dind}"
CODE_SERVER_PORT="${CODE_SERVER_PORT:-8080}"
VITE_PORT="${VITE_PORT:-5173}"

# Generate container name from workspace path hash
SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
WORKSPACE_DIR="$(cd "${SCRIPT_DIR}/.." && pwd)"
PATH_HASH=$(echo -n "${WORKSPACE_DIR}" | md5sum | cut -c1-8)
CONTAINER_NAME="${PROJECT_NAME}-${PATH_HASH}"

# ==============================================================================
# Functions
# ==============================================================================

build_mounts() {
  local mounts="-v ${WORKSPACE_DIR}:/workspaces/web-design"

  if [[ -f "${HOME}/.gitconfig" ]]; then
    mounts+=" -v ${HOME}/.gitconfig:/home/vscode/.gitconfig:ro"
  fi
  if [[ -d "${HOME}/.ssh" ]]; then
    mounts+=" -v ${HOME}/.ssh:/home/vscode/.ssh:ro"
  fi
  if [[ -d "${HOME}/.claude" ]]; then
    mounts+=" -v ${HOME}/.claude:/home/vscode/.claude:cached"
  fi
  if [[ -f "${HOME}/.claude.json" ]]; then
    mounts+=" -v ${HOME}/.claude.json:/home/vscode/.claude.json:cached"
  fi
  if [[ -d "${HOME}/.copilot" ]]; then
    mounts+=" -v ${HOME}/.copilot:/home/vscode/.copilot:cached"
  fi

  echo "${mounts}"
}

check_docker() {
  if ! docker info >/dev/null 2>&1; then
    echo "Error: Docker daemon is not running." >&2
    exit 1
  fi
}

is_running() {
  docker ps --filter "name=^${CONTAINER_NAME}$" --format '{{.Names}}' 2>/dev/null | grep -q "^${CONTAINER_NAME}$"
}

cmd_up() {
  check_docker

  if is_running; then
    echo "Container '${CONTAINER_NAME}' is already running."
    echo "  Code Server: http://localhost:${CODE_SERVER_PORT}"
    echo "  Vite:        http://localhost:${VITE_PORT}"
    exit 0
  fi

  # Remove stopped container with the same name if exists
  docker rm "${CONTAINER_NAME}" 2>/dev/null || true

  local MOUNTS
  MOUNTS="$(build_mounts)"

  echo "Starting container '${CONTAINER_NAME}' in ${DOCKER_MODE} mode..."

  if [[ "${DOCKER_MODE}" == "dind" ]]; then
    docker run -d \
      --name "${CONTAINER_NAME}" \
      --label "managed-by=dev-container-sh" \
      --label "workspace-path=${WORKSPACE_DIR}" \
      --privileged \
      -p "${CODE_SERVER_PORT}:8080" \
      -p "${VITE_PORT}:5173" \
      ${MOUNTS} \
      "${DEV_CONTAINER_IMAGE}"
  elif [[ "${DOCKER_MODE}" == "dood" ]]; then
    docker run -d \
      --name "${CONTAINER_NAME}" \
      --label "managed-by=dev-container-sh" \
      --label "workspace-path=${WORKSPACE_DIR}" \
      --privileged \
      --entrypoint start-code-server \
      -p "${CODE_SERVER_PORT}:8080" \
      -p "${VITE_PORT}:5173" \
      -v /var/run/docker.sock:/var/run/docker.sock \
      ${MOUNTS} \
      "${DEV_CONTAINER_IMAGE}"
  else
    echo "Error: Unknown DOCKER_MODE '${DOCKER_MODE}'. Use 'dind' or 'dood'." >&2
    exit 1
  fi

  echo "Container '${CONTAINER_NAME}' started."
  echo "  Code Server: http://localhost:${CODE_SERVER_PORT}"
  echo "  Vite:        http://localhost:${VITE_PORT}"
}

cmd_down() {
  echo "Stopping container '${CONTAINER_NAME}'..."
  docker stop "${CONTAINER_NAME}" 2>/dev/null || true
  docker rm "${CONTAINER_NAME}" 2>/dev/null || true
  echo "Container '${CONTAINER_NAME}' removed."
}

cmd_status() {
  docker ps -a --filter "name=^${CONTAINER_NAME}$"
}

cmd_shell() {
  if ! is_running; then
    echo "Error: Container '${CONTAINER_NAME}' is not running. Run '$0 up' first." >&2
    exit 1
  fi
  docker exec -it "${CONTAINER_NAME}" bash
}

cmd_logs() {
  docker logs -f "${CONTAINER_NAME}"
}

cmd_help() {
  cat <<EOF
Usage: $0 <command>

Commands:
  up      Start the development container
  down    Stop and remove the development container
  status  Show container status
  shell   Open a shell in the running container
  logs    Follow container logs
  help    Show this help message

Environment Variables:
  DEV_CONTAINER_IMAGE  Container image (default: nagasakah/web-design:latest)
  DOCKER_MODE          Docker mode: dind or dood (default: dind)
  CODE_SERVER_PORT     Code Server port (default: 8080)
  VITE_PORT            Vite dev server port (default: 5173)

Container: ${CONTAINER_NAME}
Workspace: ${WORKSPACE_DIR}
EOF
}

# ==============================================================================
# Main
# ==============================================================================

case "${1:-help}" in
  up)     cmd_up ;;
  down)   cmd_down ;;
  status) cmd_status ;;
  shell)  cmd_shell ;;
  logs)   cmd_logs ;;
  help)   cmd_help ;;
  *)
    echo "Error: Unknown command '${1}'" >&2
    cmd_help
    exit 1
    ;;
esac
