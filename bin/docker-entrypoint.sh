#!/usr/bin/env bash
set -e

# Support both DATABASE_URL (Railway) and individual DB_* vars (local Docker Compose)
if [ -n "$DATABASE_URL" ]; then
  DB_HOST=$(echo "$DATABASE_URL" | sed -E 's|.*@([^:/]+).*|\1|')
  DB_USERNAME=$(echo "$DATABASE_URL" | sed -E 's|.*://([^:]+):.*|\1|')
fi

until pg_isready -h "$DB_HOST" -U "$DB_USERNAME" -d postgres -q; do
  echo "Waiting for Postgres..."
  sleep 1
done

bundle exec rails db:create
bundle exec rails db:migrate
bundle exec rails db:seed

exec "$@"
