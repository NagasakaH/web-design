#!/usr/bin/env bash
set -euo pipefail

WORKSPACE_DIR="${1:-/workspaces/web-design}"
RUN_USER=vscode
CODE_SERVER_PORT=8080

# WARNING: --auth none is for local development only.
# Do NOT use this configuration in a publicly accessible environment.

if [ "$(id -u)" -eq 0 ]; then
  # Get workspace owner UID/GID
  WS_UID=$(stat -c '%u' "${WORKSPACE_DIR}" 2>/dev/null || echo "1000")
  WS_GID=$(stat -c '%g' "${WORKSPACE_DIR}" 2>/dev/null || echo "1000")

  CURRENT_UID=$(id -u "${RUN_USER}")
  CURRENT_GID=$(id -g "${RUN_USER}")

  # Adjust UID/GID if different from workspace owner (skip if root-owned)
  if [ "${WS_GID}" != "0" ] && [ "${WS_GID}" != "${CURRENT_GID}" ]; then
    if ! getent group "${WS_GID}" >/dev/null 2>&1; then
      groupmod -g "${WS_GID}" "${RUN_USER}"
    else
      usermod -g "${WS_GID}" "${RUN_USER}"
    fi
  fi
  if [ "${WS_UID}" != "0" ] && [ "${WS_UID}" != "${CURRENT_UID}" ]; then
    usermod -u "${WS_UID}" "${RUN_USER}"
  fi

  chown -R "${RUN_USER}:${RUN_USER}" "/home/${RUN_USER}" 2>/dev/null || true

  # Fix Docker socket permissions if it exists
  if [ -S /var/run/docker.sock ]; then
    DOCKER_GID=$(stat -c '%g' /var/run/docker.sock)
    if ! getent group docker >/dev/null 2>&1; then
      groupadd -g "${DOCKER_GID}" docker
    fi
    usermod -aG docker "${RUN_USER}"
    chmod 660 /var/run/docker.sock
  fi

  exec gosu "${RUN_USER}" code-server \
    --bind-addr "0.0.0.0:${CODE_SERVER_PORT}" \
    --auth none \
    --disable-telemetry \
    "${WORKSPACE_DIR}"
else
  exec code-server \
    --bind-addr "0.0.0.0:${CODE_SERVER_PORT}" \
    --auth none \
    --disable-telemetry \
    "${WORKSPACE_DIR}"
fi
