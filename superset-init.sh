#!/bin/bash
# Superset initialization script
# Runs on first container startup to configure databases

set -e

echo "Waiting for Superset to be ready..."
until superset db upgrade 2>/dev/null; do
    sleep 2
done

echo "Creating admin user..."
superset fab create-admin \
    --username admin \
    --firstname Admin \
    --lastname User \
    --email admin@superset.com \
    --password admin || echo "Admin user already exists"

echo "Initializing Superset..."
superset init

echo "Adding Trino database connection..."
superset set-database-uri -d "Trino Hive" -u "trino://admin@trino:8080/hive" || echo "Database already configured"

echo "✓ Superset initialization complete!"
