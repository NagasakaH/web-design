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

  # Adjust UID/GID if different from workspace owner
  if [ "${WS_GID}" != "${CURRENT_GID}" ]; then
    groupmod -g "${WS_GID}" "${RUN_USER}"
  fi
  if [ "${WS_UID}" != "${CURRENT_UID}" ]; then
    usermod -u "${WS_UID}" "${RUN_USER}"
  fi

  chown -R "${RUN_USER}:${RUN_USER}" "/home/${RUN_USER}"

  # Fix Docker socket permissions if it exists
  if [ -S /var/run/docker.sock ]; then
    chmod 666 /var/run/docker.sock
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
