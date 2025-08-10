#!/usr/bin/env bash
set -euo pipefail

# ------------ Config (can be overridden via env) ------------
WORKDIR="${WORKDIR:-/workspace}"
BENCH_DIR="${BENCH_DIR:-$WORKDIR/frappe-bench}"
FRAPPE_BRANCH="${FRAPPE_BRANCH:-version-15}"
PYTHON_BIN="${PYTHON_BIN:-/usr/local/bin/python3}"

DB_HOST="${DB_HOST:-db}"
DB_PORT="${DB_PORT:-5432}"
POSTGRES_USER="${POSTGRES_USER:-postgres}"
POSTGRES_PASSWORD="${POSTGRES_PASSWORD:-secret}"

REDIS_CACHE="${REDIS_CACHE:-redis://redis:6379}"
REDIS_QUEUE="${REDIS_QUEUE:-redis://redis:6379}"
REDIS_SOCKETIO="${REDIS_SOCKETIO:-redis://redis:6379}"

# Optional: pull ERPNext too (set INSTALL_ERPNEXT=true)
INSTALL_ERPNEXT="${INSTALL_ERPNEXT:-false}"
ERPNEXT_BRANCH="${ERPNEXT_BRANCH:-version-15}"

echo "🏁 Bootstrap starting..."
echo "  Workdir: $WORKDIR"
echo "  Bench:   $BENCH_DIR"
echo "  Frappe:  $FRAPPE_BRANCH"
echo "  DB:      postgres@$DB_HOST:$DB_PORT"

# ------------ Ensure bench CLI is available ------------
if ! command -v bench >/dev/null 2>&1; then
  echo "➡️  Installing bench via pipx..."
  python3 -m pip install --upgrade pip pipx >/dev/null
  python3 -m pipx ensurepath >/dev/null
  pipx install "frappe-bench==5.*" honcho
fi

# ------------ Wait for PostgreSQL to be ready ------------
echo "⏳ Waiting for PostgreSQL at ${DB_HOST}:${DB_PORT}..."
export PGPASSWORD="${POSTGRES_PASSWORD}"
until pg_isready -h "${DB_HOST}" -p "${DB_PORT}" -U "${POSTGRES_USER}" >/dev/null 2>&1; do
  sleep 2
done
echo "✅ PostgreSQL is up."

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

# ------------ Global config (use Docker hosts) ------------
echo "➡️  Writing bench global config..."
bench set-config -g db_host "${DB_HOST}"
bench set-config -g redis_cache "${REDIS_CACHE}"
bench set-config -g redis_queue "${REDIS_QUEUE}"
bench set-config -g redis_socketio "${REDIS_SOCKETIO}"
