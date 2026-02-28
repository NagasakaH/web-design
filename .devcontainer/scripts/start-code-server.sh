#!/usr/bin/env bash
set -euo pipefail

WORKSPACE_DIR="${1:-/workspaces/web-design}"
RUN_USER=vscode
CODE_SERVER_PORT=8080
CODE_SERVER_HTTPS="${CODE_SERVER_HTTPS:-false}"
CERT_DIR="/home/${RUN_USER}/.local/share/code-server/certs"

# WARNING: --auth none is for local development only.
# Do NOT use this configuration in a publicly accessible environment.

generate_self_signed_cert() {
  mkdir -p "${CERT_DIR}"

  # Collect all container IPs for SAN
  local san_entries="DNS:localhost,IP:127.0.0.1"
  local ips
  ips=$(hostname -I 2>/dev/null || true)
  for ip in ${ips}; do
    san_entries="${san_entries},IP:${ip}"
  done

  openssl req -x509 -nodes -days 365 \
    -newkey rsa:2048 \
    -keyout "${CERT_DIR}/key.pem" \
    -out "${CERT_DIR}/cert.pem" \
    -subj "/CN=code-server-dev" \
    -addext "subjectAltName=${san_entries}" \
    2>/dev/null

  chown -R "${RUN_USER}:${RUN_USER}" "${CERT_DIR}"
  echo "Self-signed certificate generated for: ${san_entries}"
}

build_code_server_args() {
  local args="--bind-addr 0.0.0.0:${CODE_SERVER_PORT} --auth none --disable-telemetry"
  if [ "${CODE_SERVER_HTTPS}" = "true" ]; then
    args="${args} --cert ${CERT_DIR}/cert.pem --cert-key ${CERT_DIR}/key.pem"
  fi
  echo "${args}"
}

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

  # Generate self-signed certificate if HTTPS is enabled
  if [ "${CODE_SERVER_HTTPS}" = "true" ]; then
    generate_self_signed_cert
  fi

  CS_ARGS=$(build_code_server_args)
  # shellcheck disable=SC2086
  exec gosu "${RUN_USER}" code-server ${CS_ARGS} "${WORKSPACE_DIR}"
else
  if [ "${CODE_SERVER_HTTPS}" = "true" ]; then
    generate_self_signed_cert
  fi

  CS_ARGS=$(build_code_server_args)
  # shellcheck disable=SC2086
  exec code-server ${CS_ARGS} "${WORKSPACE_DIR}"
fi
