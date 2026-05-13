#!/bin/bash
set -e

DATABASE_URL="jdbc:postgresql://$POSTGRES_HOST:$POSTGRES_PORT/$POSTGRES_USER"

flyway migrate \
  -url=$DATABASE_URL \
  -user=$POSTGRES_USER \
  -password=$POSTGRES_PASSWORD \
  -locations="filesystem:/app/sql" \
  -baselineOnMigrate=true \
  -connectRetries=60