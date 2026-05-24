#!/usr/bin/env bash
set -e

until pg_isready -h "$DB_HOST" -U "$DB_USERNAME" -d postgres -q; do
  echo "Waiting for Postgres..."
  sleep 1
done

bundle exec rails db:create
bundle exec rails db:migrate
bundle exec rails db:seed

exec "$@"
