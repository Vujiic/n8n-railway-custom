#!/usr/bin/env bash
set -e

# 1) Encryption key (uzmi iz N8N_ENCRYPTION_KEY ili fallback na ENCRYPTIONKEY)
: "${N8N_ENCRYPTION_KEY:=${ENCRYPTIONKEY:-}}"
export N8N_ENCRYPTION_KEY

# 2) Tip baze
export DB_TYPE="${DB_TYPE:-postgresdb}"

# 3) Ako postoji DATABASE_URL (npr. sa Railway-a), prosledi ga direktno n8n-u
#    n8n podržava DB_POSTGRESDB_CONNECTION_STRING
if [ -n "${DATABASE_URL:-}" ] && [ -z "${DB_POSTGRESDB_CONNECTION_STRING:-}" ]; then
  export DB_POSTGRESDB_CONNECTION_STRING="$DATABASE_URL"
fi

# 4) Ako nema connection string-a, mapiraj PG* -> n8n varijable
export DB_POSTGRESDB_HOST="${DB_POSTGRESDB_HOST:-${PGHOST:-localhost}}"
export DB_POSTGRESDB_PORT="${DB_POSTGRESDB_PORT:-${PGPORT:-5432}}"
export DB_POSTGRESDB_USER="${DB_POSTGRESDB_USER:-${PGUSER:-postgres}}"
export DB_POSTGRESDB_PASSWORD="${DB_POSTGRESDB_PASSWORD:-${PGPASSWORD:-}}"
export DB_POSTGRESDB_DATABASE="${DB_POSTGRESDB_DATABASE:-${PGDATABASE:-postgres}}"

# 5) SSL: ako cloud traži SSL (sslmode=require u DATABASE_URL ili PGSSLMODE=require)
if [ -z "${DB_POSTGRESDB_SSL:-}" ]; then
  if echo "${DATABASE_URL:-$PGSSLMODE}" | grep -qi "require"; then
    export DB_POSTGRESDB_SSL=true
    export DB_POSTGRESDB_SSL_REJECT_UNAUTHORIZED="${DB_POSTGRESDB_SSL_REJECT_UNAUTHORIZED:-false}"
  fi
fi

# 6) Permissions warning fix za n8n config
mkdir -p /data/.n8n || true
if [ -f /data/.n8n/config ]; then
  chmod 600 /data/.n8n/config || true
fi
export N8N_ENFORCE_SETTINGS_FILE_PERMISSIONS="${N8N_ENFORCE_SETTINGS_FILE_PERMISSIONS:-true}"

# 7) Port (Railway setuje $PORT)
export N8N_PORT="${PORT:-5678}"
echo "PORT=$N8N_PORT"

exec "$@"
