# DBT Production Environment Addon

**Production-grade data transformation with DBT + Great Expectations**

This addon provides a complete production-ready setup for learning and practicing modern data transformation workflows with multi-environment deployments, automated testing, and data quality validation.

[![DBT](https://img.shields.io/badge/DBT-1.7-orange)](https://www.getdbt.com/)
[![Great Expectations](https://img.shields.io/badge/Great_Expectations-0.18-blue)](https://greatexpectations.io/)
[![CI/CD](https://img.shields.io/badge/CI%2FCD-Airflow-green)](https://airflow.apache.org/)

---

## What You'll Learn

This addon teaches **real production patterns** used by data teams at companies like Airbnb, Spotify, and Netflix:

✅ **Multi-environment architecture** (dev → prod)  
✅ **Schema isolation** (dev_analytics vs analytics)  
✅ **Automated testing** with DBT tests  
✅ **Data quality validation** with Great Expectations  
✅ **CI/CD pipelines** via Airflow  
✅ **Promotion workflows** with quality gates  
✅ **Production monitoring** and alerting  

---

## Architecture

```
┌──────────────────────────────────────────────────────────┐
│                   Development Workflow                    │
├──────────────────────────────────────────────────────────┤
│                                                           │
│  1. DEV ENVIRONMENT (hive.dev_analytics.*)               │
│     ┌──────────┐                                         │
│     │ dbt-dev  │  → Run models                          │
│     │ container│  → Run tests                           │
│     └──────────┘  → Validate with GX                    │
│          ↓                                               │
│                                                          │
│  2. QUALITY GATES                                        │
│     ┌─────────────────┐                                 │
│     │ Great           │  → Data validation              │
│     │ Expectations    │  → Quality thresholds          │
│     └─────────────────┘  → Promotion approval          │
│          ↓                                               │
│                                                          │
│  3. PRODUCTION ENVIRONMENT (hive.analytics.*)            │
│     ┌───────────┐                                        │
│     │ dbt-prod  │  → Deploy models                      │
│     │ container │  → Run tests                          │
│     └───────────┘  → Monitor quality                    │
│                                                          │
│  4. ORCHESTRATION (Airflow CI/CD)                       │
│     ┌──────────────────────────────────────┐            │
│     │ dbt_production_cicd_pipeline         │            │
│     │  • Dev build → Test → Validate       │            │
│     │  • Promotion gate                    │            │
│     │  • Prod deploy → Test → Monitor      │            │
│     └──────────────────────────────────────┘            │
│                                                          │
└──────────────────────────────────────────────────────────┘
```

---

## Components

### 1. DBT Containers (2)

| Container | Purpose | Schema | Port |
|-----------|---------|--------|------|
| `dbt-dev` | Development environment | `hive.dev_analytics.*` | - |
| `dbt-prod` | Production environment | `hive.analytics.*` | - |

### 2. Great Expectations Container

| Component | Purpose | Port |
|-----------|---------|------|
| `great-expectations` | Data quality validation & monitoring | 8083 |

**Capabilities:**
- Pre-deployment validation
- Data quality gates
- Production monitoring
- Interactive Data Docs UI

### 3. DBT Models (7)

**Staging Layer** (`stg_*`):
- `stg_employees` - Cleaned and standardized employee data

**Intermediate Layer** (`int_*`):
- `int_employee_metrics` - Employee-level calculations
- `int_department_stats` - Department aggregations

**Marts Layer** (`fct_*`, `dim_*`, `rpt_*`):
- `dim_employees` - Employee dimension
- `fct_department_summary` - Department facts
- `fct_high_earners` - High performer tracking
- `rpt_compensation_analysis` - Executive report

### 4. Great Expectations Suites (3)

| Suite | Purpose | When |
|-------|---------|------|
| `dev_validation_suite` | Validate dev data quality | After dev run |
| `prod_promotion_suite` | Gate promotion to prod | Before deployment |
| `prod_monitoring_suite` | Monitor prod data health | Post-deployment |

---

## Prerequisites

- Core Local Analytics Lab running
- Sample employee data loaded in `hive.analytics.employees`
- Docker with 4GB+ available RAM
- Disk space: 2GB

---

## Quick Start

### 1. Install the Addon

```bash
# From project root
just addon-dbt-prod-install
```

This will:
- Start 3 containers (dbt-dev, dbt-prod, great-expectations)
- Create dev and prod schemas in Trino
- Install DBT dependencies
- Initialize Great Expectations

**Wait 2-3 minutes** for initialization to complete.

### 2. Run Dev Pipeline

```bash
# Run all models in dev
just dbt-prod-dev-run

# Test data quality
just dbt-prod-dev-test

# Validate with Great Expectations
just dbt-prod-gx-validate-dev
```

### 3. Query Dev Results

```bash
# Check what was created
just dbt-prod-dev-query "SHOW TABLES"

# Query a model
just dbt-prod-dev-query "SELECT * FROM dim_employees LIMIT 10"

# Check department summary
just dbt-prod-dev-query "SELECT * FROM fct_department_summary"
```

### 4. Promote to Production

```bash
# Automated promotion with quality gates
just dbt-prod-promote
```

This runs the full promotion workflow:
1. ✓ Validate dev data quality
2. ✓ Run promotion checks
3. ✓ Deploy to production
4. ✓ Test production models
5. ✓ Monitor production health

### 5. View Results

```bash
# Query production data
just dbt-prod-query "SELECT * FROM dim_employees LIMIT 10"

# View Great Expectations Data Docs
just dbt-prod-gx-docs
# Opens: http://localhost:8083

# View DBT documentation
just dbt-prod-docs-prod
# Opens: http://localhost:8085
```

---

## Development Workflow

### Typical Day-to-Day Workflow

```bash
# 1. Make changes to DBT models
vim addons/dbt-production/dbt-project/models/marts/my_new_model.sql

# 2. Run only your new model in dev
just dbt-prod-dev-run-model my_new_model

# 3. Test your model
just dbt-prod-dev-test-model my_new_model

# 4. Query results
just dbt-prod-dev-query "SELECT * FROM my_new_model"

# 5. If good, run full dev pipeline
just dbt-prod-dev-pipeline

# 6. Promote to production
just dbt-prod-promote
```

### Using Airflow CI/CD

For automated workflows:

```bash
# Copy DAG to Airflow
cp addons/dbt-production/airflow-dags/*.py dags/

# Trigger via Airflow UI
# Visit: http://localhost:8080
# DAG: dbt_production_cicd_pipeline
# Click: Trigger DAG

# Or trigger via CLI
just dbt-prod-cicd-trigger
```

---

## Available Commands

### Installation & Management

```bash
just addon-dbt-prod-install    # Install addon
just addon-dbt-prod-status     # Check status
just addon-dbt-prod-stop       # Stop containers
just addon-dbt-prod-start      # Start containers
just addon-dbt-prod-down       # Remove containers
just addon-dbt-prod-clean      # Remove everything
```

### Dev Environment

```bash
just dbt-prod-dev-run              # Run all models
just dbt-prod-dev-run-model MODEL  # Run specific model
just dbt-prod-dev-test             # Test all models
just dbt-prod-dev-test-model MODEL # Test specific model
just dbt-prod-dev-refresh          # Full refresh (rebuild)
just dbt-prod-dev-compile          # Compile without running
just dbt-prod-dev-query "SQL"      # Query dev data
just dbt-prod-dev-shell            # Open bash shell
```

### Production Environment

```bash
just dbt-prod-run              # Run all models
just dbt-prod-run-model MODEL  # Run specific model
just dbt-prod-test             # Test all models
just dbt-prod-query "SQL"      # Query prod data
just dbt-prod-shell            # Open bash shell
```

### Great Expectations

```bash
just dbt-prod-gx-validate-dev        # Validate dev
just dbt-prod-gx-validate-promotion  # Check promotion readiness
just dbt-prod-gx-monitor-prod        # Monitor production
just dbt-prod-gx-docs                # Open Data Docs UI
just dbt-prod-gx-shell               # Open bash shell
```

### CI/CD Workflows

```bash
just dbt-prod-dev-pipeline    # Full dev pipeline
just dbt-prod-promote         # Manual promotion
just dbt-prod-cicd-trigger    # Trigger Airflow DAG
```

### Documentation

```bash
just dbt-prod-docs-dev     # Serve dev docs (port 8084)
just dbt-prod-docs-prod    # Serve prod docs (port 8085)
just dbt-prod-gx-docs      # Open GX Data Docs (port 8083)
```

---

## Understanding the Models

### Data Flow

```
Source: hive.analytics.employees (raw data from Spark)
    ↓
Staging: stg_employees (cleaning, standardization)
    ↓
Intermediate: int_employee_metrics (calculations)
                int_department_stats (aggregations)
    ↓
Marts: dim_employees (dimension table)
       fct_department_summary (fact table)
       fct_high_earners (filtered facts)
       rpt_compensation_analysis (report)
```

### Model Details

**stg_employees** (View)
- Cleans raw employee data
- Standardizes department names
- Filters invalid records
- Adds load timestamp

**int_employee_metrics** (View)
- Calculates salary percentiles
- Compares to department averages
- Flags high earners
- Categorizes by career stage

**int_department_stats** (View)
- Aggregates by department
- Calculates salary statistics
- Counts employees per department

**dim_employees** (Table)
- Production employee dimension
- Includes all metrics
- Updated timestamp tracking

**fct_department_summary** (Table)
- Department-level facts
- Salary statistics
- Employee counts
- Payroll totals

**fct_high_earners** (Table)
- Top 25% by salary
- Performance tracking
- Comparison metrics

**rpt_compensation_analysis** (Table)
- Executive reporting
- Department comparisons
- High earner percentages

---

## Testing Strategy

### DBT Tests (Automated)

**Generic Tests** (schema.yml):
- `not_null` - No NULL values
- `unique` - No duplicates
- `accepted_values` - Valid enumerations
- `accepted_range` - Value boundaries

**Custom Tests** (tests/*.sql):
- `assert_salary_range` - Salary within 30k-500k
- `assert_department_counts_match` - Referential integrity

**Test Execution**:
```bash
# Run all tests
just dbt-prod-dev-test

# Run specific test
just dbt-prod-dev-test-model stg_employees

# View test results
# Check: addons/dbt-production/dbt-project/target/run_results.json
```

### Great Expectations (Data Quality)

**Dev Validation**:
- Row count checks
- Column completeness
- Value range validation
- Set membership checks

**Promotion Gates**:
- Stricter thresholds
- Aggregation validation
- Cross-table consistency

**Production Monitoring**:
- Ongoing health checks
- Anomaly detection
- Data freshness

---

## Promotion Process

### Manual Promotion

```bash
just dbt-prod-promote
```

**Steps**:
1. **Dev Validation** - Ensures dev data quality
2. **Promotion Checks** - Validates readiness
3. **Production Deploy** - Runs models in prod
4. **Production Tests** - Validates prod data
5. **Production Monitoring** - Checks health

### Automated Promotion (Airflow)

**DAG**: `dbt_production_cicd_pipeline`

**Workflow**:
```
Start
  → Install dependencies
  → Run dev models
  → Test dev models
  → Generate dev docs
  → GX dev validation
  → Promotion gate (decision point)
  → GX promotion validation
  → Deploy to prod
  → Test prod models
  → GX prod monitoring
  → Generate prod docs
  → Build GX data docs
  → Log summary
End
```

**Trigger**:
```bash
# Via justfile
just dbt-prod-cicd-trigger

# Via Airflow UI
# Go to: http://localhost:8080
# Find: dbt_production_cicd_pipeline
# Click: Play button
```

---

## Troubleshooting

### Models Won't Run

```bash
# Check DBT connection
docker exec dbt-dev dbt debug --target dev

# View compiled SQL
just dbt-prod-dev-compile

# Check Trino schemas
just trino-query "SHOW SCHEMAS IN hive LIKE '%analytics%'"

# View DBT logs
just dbt-prod-logs-dev
```

### Tests Failing

```bash
# Run single test to isolate issue
just dbt-prod-dev-test-model stg_employees

# Check test SQL
cat addons/dbt-production/dbt-project/tests/assert_salary_range.sql

# Query failing records
just dbt-prod-dev-query "SELECT * FROM stg_employees WHERE salary > 500000"

# Store failures for analysis
docker exec dbt-dev dbt test --store-failures
just dbt-prod-dev-query "SELECT * FROM test_failures.unique_stg_employees_employee_id"
```

### Great Expectations Failing

```bash
# View GX logs
just dbt-prod-logs-gx

# Open Data Docs to see failures
just dbt-prod-gx-docs

# Run checkpoint manually
docker exec great-expectations python << EOF
import great_expectations as gx
context = gx.get_context()
result = context.get_checkpoint("dev_checkpoint").run()
print(result)
EOF
```

### Can't Connect to Trino

```bash
# Verify Trino is running
docker-compose ps trino

# Test connection
just trino-cli
# Then: SHOW SCHEMAS IN hive;

# Check network
docker exec dbt-dev ping -c 3 trino
```

### Out of Memory

```bash
# Check Docker resources
docker stats

# Reduce DBT threads in profiles.yml
# Change: threads: 4 → threads: 2

# Stop other addons
just addon-datahub-stop
```

---

## Production Best Practices

### 1. Schema Isolation

**Always** use separate schemas:
- Dev: `hive.dev_analytics.*`
- Prod: `hive.analytics.*`

Never point dev directly at prod schemas.

### 2. Testing Before Promotion

**Minimum tests before prod**:
- ✓ All DBT tests pass
- ✓ GX validation passes
- ✓ Manual spot checks
- ✓ Stakeholder review (real scenarios)

### 3. Incremental Deployments

For large changes:
```bash
# Deploy one model at a time
just dbt-prod-run-model stg_employees
just dbt-prod-test-model stg_employees

# Then next model
just dbt-prod-run-model int_employee_metrics
# etc.
```

### 4. Monitor Production

Set up recurring validation:
```bash
# In real production, run this on schedule (e.g., every 6 hours)
just dbt-prod-gx-monitor-prod
```

### 5. Document Everything

Add descriptions to every model:
```yaml
# models/schema.yml
models:
  - name: dim_employees
    description: "Employee dimension table - PRODUCTION"
    columns:
      - name: employee_id
        description: "Primary key - unique employee identifier"
```

### 6. Version Control

In real scenarios:
- Store DBT project in Git
- Use branches for features
- Pull request reviews
- CI/CD on merge to main

---

## Integration with Other Tools

### Superset Dashboards

```bash
# Add dev data source
just superset-ui
# Add Database: Trino Dev
# SQLAlchemy URI: trino://admin@trino:8080/hive/dev_analytics_marts

# Create charts from marts
# Dataset: dim_employees
# Chart: Department distribution
```

### DataHub Lineage

If DataHub addon installed:
```bash
# Install DBT DataHub integration
docker exec dbt-dev pip install acryl-datahub[dbt]

# Generate and push lineage
docker exec dbt-dev dbt run
docker exec dbt-dev dbt docs generate
# Ingest to DataHub (requires configuration)
```

### Spark Integration

Your Spark jobs write to `hive.analytics.employees`, which DBT transforms. Full pipeline:

```
Spark → hive.analytics.employees (raw)
  ↓
DBT → hive.analytics.* (transformed)
  ↓
Superset → Dashboards
DataHub → Lineage
```

---

## Advanced Topics

### Custom Macros

Create reusable SQL functions:

```sql
-- macros/generate_schema_name.sql
{% macro generate_schema_name(custom_schema_name, node) -%}
    {%- set default_schema = target.schema -%}
    {%- if custom_schema_name is none -%}
        {{ default_schema }}
    {%- else -%}
        {{ default_schema }}_{{ custom_schema_name | trim }}
    {%- endif -%}
{%- endmacro %}
```

### Incremental Models

For large tables, use incremental materialization:

```sql
{{
  config(
    materialized='incremental',
    unique_key='employee_id'
  )
}}

select * from {{ ref('stg_employees') }}

{% if is_incremental() %}
  where loaded_at > (select max(loaded_at) from {{ this }})
{% endif %}
```

### Snapshots

Track slowly changing dimensions:

```sql
-- snapshots/employee_snapshot.sql
{% snapshot employee_snapshot %}
{{
    config(
      target_schema='snapshots',
      unique_key='employee_id',
      strategy='timestamp',
      updated_at='updated_at',
    )
}}
select * from {{ ref('dim_employees') }}
{% endsnapshot %}
```

---

## Learning Resources

### DBT Documentation
- [DBT Getting Started](https://docs.getdbt.com/docs/introduction)
- [DBT Best Practices](https://docs.getdbt.com/guides/best-practices)
- [DBT Testing](https://docs.getdbt.com/docs/build/tests)

### Great Expectations
- [GX Quick Start](https://docs.greatexpectations.io/docs/)
- [Expectation Gallery](https://greatexpectations.io/expectations/)
- [Data Docs](https://docs.greatexpectations.io/docs/terms/data_docs)

### Real-World Examples
- [GitLab Analytics](https://about.gitlab.com/handbook/business-technology/data-team/platform/dbt-guide/)
- [Buffer Data Team](https://buffer.com/resources/data-team-dbt/)
- [Fishtown Analytics (DBT Labs)](https://www.getdbt.com/blog/)

---

## Uninstall

### Remove Addon (Keep Data)

```bash
just addon-dbt-prod-down
```

### Remove Everything

```bash
# Remove containers and volumes
just addon-dbt-prod-clean

# Remove schemas from Trino
just trino-query "DROP SCHEMA IF EXISTS hive.dev_analytics CASCADE"
just trino-query "DROP SCHEMA IF EXISTS hive.analytics CASCADE"
```

---

## Support

- **Documentation**: See `docs/` folder
- **Issues**: Check existing docs first
- **Questions**: Review workflow examples
- **Contributing**: See main [CONTRIBUTING.md](../../CONTRIBUTING.md)

---

**Ready to build production-grade data pipelines! 🚀**
