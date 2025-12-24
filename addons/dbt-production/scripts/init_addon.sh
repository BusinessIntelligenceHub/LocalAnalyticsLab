#!/bin/bash
set -e

echo "=========================================="
echo "  DBT Production Addon - Initialization"
echo "=========================================="
echo ""

# Colors for output
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

echo -e "${YELLOW}Step 1: Creating Trino schemas...${NC}"
docker-compose exec -T trino trino --execute "$(cat scripts/init_schemas.sql)"
echo -e "${GREEN}✓ Schemas created${NC}"
echo ""

echo -e "${YELLOW}Step 2: Installing DBT dependencies...${NC}"
docker exec dbt-dev dbt deps
echo -e "${GREEN}✓ DBT dependencies installed${NC}"
echo ""

echo -e "${YELLOW}Step 3: Testing DBT connection (dev)...${NC}"
docker exec dbt-dev dbt debug --target dev
echo -e "${GREEN}✓ Dev connection successful${NC}"
echo ""

echo -e "${YELLOW}Step 4: Testing DBT connection (prod)...${NC}"
docker exec dbt-prod dbt debug --target prod
echo -e "${GREEN}✓ Prod connection successful${NC}"
echo ""

echo -e "${YELLOW}Step 5: Initializing Great Expectations...${NC}"
docker exec great-expectations python /scripts/init_great_expectations.py
echo -e "${GREEN}✓ Great Expectations initialized${NC}"
echo ""

echo -e "${GREEN}=========================================="
echo -e "  Initialization Complete!"
echo -e "==========================================${NC}"
echo ""
echo "Next steps:"
echo "  1. Run dev pipeline:     just dbt-prod-dev-run"
echo "  2. Test models:          just dbt-prod-dev-test"
echo "  3. Validate with GX:     just dbt-prod-gx-validate-dev"
echo "  4. Promote to prod:      just dbt-prod-promote"
echo ""
echo "Or run full CI/CD pipeline via Airflow:"
echo "  - Trigger DAG: dbt_production_cicd_pipeline"
echo ""
