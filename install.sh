#!/bin/bash
set -e

echo "=================================================="
echo "  Local Analytics Lab - Installation Script"
echo "=================================================="
echo ""

# Check prerequisites
echo "Checking prerequisites..."

# Check Docker
if ! command -v docker &> /dev/null; then
    echo "❌ Docker not found. Please install Docker Desktop from https://www.docker.com/products/docker-desktop"
    exit 1
fi
echo "✓ Docker installed"

# Check Docker Compose
if ! docker compose version &> /dev/null; then
    echo "❌ Docker Compose not found. Please install Docker Desktop which includes Docker Compose"
    exit 1
fi
echo "✓ Docker Compose installed"

# Check Just
if ! command -v just &> /dev/null; then
    echo "⚠️  Just not found. Installing via Homebrew..."
    if command -v brew &> /dev/null; then
        brew install just
        echo "✓ Just installed"
    else
        echo "❌ Homebrew not found. Please install Just manually:"
        echo "   brew install just"
        echo "   or visit: https://github.com/casey/just"
        exit 1
    fi
else
    echo "✓ Just installed"
fi

echo ""
echo "=================================================="
echo "  Prerequisites satisfied!"
echo "=================================================="
echo ""

# Create necessary directories
echo "Creating directories..."
mkdir -p dags logs plugins config

# Initialize services
echo ""
echo "Starting services (this may take a few minutes)..."
echo ""
just up

echo ""
echo "=================================================="
echo "  Installation Complete!"
echo "=================================================="
echo ""
echo "Services are starting up. Please wait ~90 seconds for initialization."
echo ""
echo "Access your services at:"
echo "  • Airflow:       http://localhost:8080  (airflow/airflow)"
echo "  • Superset:      http://localhost:8088  (admin/admin)"
echo "  • Trino:         http://localhost:8082"
echo "  • MinIO Console: http://localhost:9001  (minioadmin/minioadmin)"
echo "  • Spark Master:  http://localhost:8081"
echo ""
echo "Optional add-ons:"
echo "  • DataHub:       just addon-datahub-install"
echo ""
echo "Check status: just ps"
echo "View logs:    just logs"
echo ""
echo "For more commands, run: just --list"
echo ""
