# Quick Reference Card

## 🚀 Installation

```bash
# Clone and install core stack
./install.sh

# Wait 60 seconds, then access:
# Airflow:  http://localhost:8080 (airflow/airflow)
# Superset: http://localhost:8088 (admin/admin)
# Trino:    http://localhost:8082
# MinIO:    http://localhost:9001 (minioadmin/minioadmin)
# Spark:    http://localhost:8081
```

## 📦 Core Commands

```bash
just up        # Start all core services
just down      # Stop all core services
just ps        # Check status
just logs      # View all logs
just clean     # Remove everything (fresh start)
```

## 🔌 Optional DataHub Addon

```bash
# Install DataHub (requires core running)
just addon-datahub-install

# Wait 2-3 minutes, then access:
# DataHub: http://localhost:9002 (datahub/datahub)

# Manage DataHub
just addon-datahub-status   # Check status
just addon-datahub-logs     # View logs
just addon-datahub-ui       # Open browser
just addon-datahub-stop     # Stop (keep data)
just addon-datahub-clean    # Remove completely
```

## 🧪 Test Data Pipeline

```bash
# 1. Test Spark → MinIO
docker-compose exec spark-master /opt/spark/bin/spark-submit /opt/spark-apps/test_spark_minio.py

# 2. Query via Trino
just trino-cli
SELECT * FROM hive.analytics.employees LIMIT 10;

# 3. View in Superset
# Go to http://localhost:8088
# Navigate to: SQL Lab → SQL Editor
# Select: Database: "Trino Hive"
# Run: SELECT * FROM analytics.employees
```

## 🛠️ Troubleshooting

```bash
# Service won't start?
just logs [service-name]

# Out of resources?
docker system prune -a

# Nuclear option?
just clean
just up
```

## 📊 Service Ports

| Service | Port | Auth |
|---------|------|------|
| Airflow | 8080 | airflow/airflow |
| Superset | 8088 | admin/admin |
| Trino | 8082 | none |
| MinIO Console | 9001 | minioadmin/minioadmin |
| Spark Master | 8081 | none |
| DataHub* | 9002 | datahub/datahub |
| Postgres | 5433 | airflow/airflow |
| MySQL Hive | 3307 | root/admin |

*Only if addon installed

## 🎯 Common Tasks

### Airflow DAGs
```bash
# Add DAG
cp my_dag.py dags/

# Check DAG
just logs airflow-scheduler

# Trigger DAG
# Go to http://localhost:8080
```

### Spark Jobs
```bash
# Open Spark shell
just spark-shell

# Submit Spark job
just spark-submit /path/to/job.py

# View Spark UI
open http://localhost:8081
```

### Trino Queries
```bash
# Open Trino CLI
just trino-cli

# Run query from command line
just trino-query "SHOW SCHEMAS FROM hive"
```

### Superset Dashboards
```bash
# Open Superset
just superset-ui

# Add dataset
# 1. Data → Datasets → + Dataset
# 2. Select: Trino Hive database
# 3. Choose table: analytics.employees

# Create chart
# 1. Charts → + Chart
# 2. Select dataset and visualization type
```

### MinIO Buckets
```bash
# Open MinIO console
open http://localhost:9001

# Or use mc CLI
docker-compose exec spark-master mc alias set myminio http://minio:9000 minioadmin minioadmin
docker-compose exec spark-master mc ls myminio/
```

## 📖 Documentation

- **Full README**: [README.md](README.md)
- **Setup Journey**: [SETUP_JOURNEY.md](SETUP_JOURNEY.md)
- **DataHub Addon**: [addons/datahub/README.md](addons/datahub/README.md)
- **All Addons**: [addons/README.md](addons/README.md)
- **Contributing**: [CONTRIBUTING.md](CONTRIBUTING.md)

## 🆘 Help

```bash
# List all commands
just --list

# Get help for specific tool
docker-compose exec [service] [command] --help
```

## ⚡ Pro Tips

1. **Use just**: It's faster than typing docker-compose commands
2. **Check logs first**: Most issues show up in service logs
3. **Wait for healthy**: Services need time to initialize
4. **Save resources**: Stop addons you're not using
5. **Backup data**: Use `just clean` carefully (removes all data)

---

**For full documentation, see [README.md](README.md)**
