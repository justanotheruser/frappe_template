#!/usr/bin/env bash
set -euo pipefail

# ------------ Config (can be overridden via env) ------------
WORKDIR="${WORKDIR:-/workspace}"
BENCH_DIR="${BENCH_DIR:-$WORKDIR/frappe-bench}"
FRAPPE_BRANCH="${FRAPPE_BRANCH:-version-14}"
PYTHON_BIN="${PYTHON_BIN:-/usr/local/bin/python3}"

# From docker-compose.yml (already set on app service)
DB_HOST="${DB_HOST:-db}"
DB_PORT="${DB_PORT:-3306}"
MYSQL_ROOT_PASSWORD="${MYSQL_ROOT_PASSWORD:-secret}"
REDIS_CACHE="${REDIS_CACHE:-redis://redis:6379}"
REDIS_QUEUE="${REDIS_QUEUE:-redis://:6379}"
REDIS_SOCKETIO="${REDIS_SOCKETIO:-redis://:6379}"

# Optional: pull ERPNext too (set INSTALL_ERPNEXT=true)
INSTALL_ERPNEXT="${INSTALL_ERPNEXT:-false}"
ERPNEXT_BRANCH="${ERPNEXT_BRANCH:-version-14}"

echo "🏁 Bootstrap starting..."
echo "  Workdir: $WORKDIR"
echo "  Bench:   $BENCH_DIR"
echo "  Frappe:  $FRAPPE_BRANCH"

# ------------ Ensure bench CLI is available ------------
if ! command -v bench >/dev/null 2>&1; then
  echo "➡️  Installing bench via pipx..."
  python3 -m pip install --upgrade pip pipx >/dev/null
  python3 -m pipx ensurepath >/dev/null
  pipx install "frappe-bench==5.*"
fi

# ------------ Wait for MariaDB to be ready ------------
echo "⏳ Waiting for MariaDB at ${DB_HOST}:${DB_PORT}..."
until mysqladmin ping -h"${DB_HOST}" -P"${DB_PORT}" -uroot -p"${MYSQL_ROOT_PASSWORD}" --silent; do
  sleep 2
done
echo "✅ MariaDB is up."

# ------------ Create bench if missing ------------
if [ ! -d "${BENCH_DIR}" ]; then
  echo "➡️  Creating bench at ${BENCH_DIR}..."
  cd "${WORKDIR}"
  bench init --frappe-branch "${FRAPPE_BRANCH}" --python "${PYTHON_BIN}" "$(basename "${BENCH_DIR}")"
else
  echo "ℹ️  Bench already exists, skipping init."
fi

cd "${BENCH_DIR}"

# ------------ Ensure frappe app present ------------
if [ ! -d "apps/frappe" ]; then
  echo "➡️  Getting frappe (${FRAPPE_BRANCH})..."
  bench get-app --branch "${FRAPPE_BRANCH}" https://github.com/frappe/frappe
fi

# Optional ERPNext
if [ "${INSTALL_ERPNEXT}" = "true" ] && [ ! -d "apps/erpnext" ]; then
  echo "➡️  Getting ERPNext (${ERPNEXT_BRANCH})..."
  bench get-app --branch "${ERPNEXT_BRANCH}" https://github.com/frappe/erpnext
fi

# ------------ Global config (use Docker hosts) ------------
echo "➡️  Writing bench global config..."
bench set-config -g db_host "${DB_HOST}"
bench set-config -g redis_cache "${REDIS_CACHE}"
bench set-config -g redis_queue "${REDIS_QUEUE}"
bench set-config -g redis_socketio "${REDIS_SOCKETIO}"