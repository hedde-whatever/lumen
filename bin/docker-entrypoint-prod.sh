#!/usr/bin/env bash
set -e

DB_HOST=$(echo "$DATABASE_URL" | sed -E 's|.*@([^:/]+).*|\1|')
DB_USERNAME=$(echo "$DATABASE_URL" | sed -E 's|.*://([^:]+):.*|\1|')

until pg_isready -h "$DB_HOST" -U "$DB_USERNAME" -d postgres -q; do
  echo "Waiting for Postgres..."
  sleep 1
done

bundle exec rails db:migrate

exec "$@"
