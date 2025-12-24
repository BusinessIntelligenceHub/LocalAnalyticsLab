# Local Analytics Lab

**Complete local analytics stack** with Airflow, Spark, MinIO, Hive, Trino, and Superset - ready to use in minutes!

[![License: MIT](https://img.shields.io/badge/License-MIT-yellow.svg)](https://opensource.org/licenses/MIT)
[![Docker](https://img.shields.io/badge/Docker-Required-blue.svg)](https://www.docker.com/)

> A fully configured, production-ready local analytics environment for learning, experimentation, and development.

---

## Features

🚀 **One-Command Setup** - Start entire stack with `./install.sh`  
🔧 **Pre-Configured** - All services connected and ready to use  
📊 **Complete Stack** - From orchestration to visualization  
💾 **Persistent Data** - Survives restarts and reboots  
🎯 **Sample Data** - Includes test dataset to explore immediately  
🔌 **Extensible** - Add optional components like DataHub  
📖 **Well Documented** - Comprehensive guides and examples  

---

## System Requirements

**Base Stack:**
- **macOS** (tested on macOS 15.3.1, Apple Silicon & Intel)
- **Docker Desktop** 4.x or later
- **8GB RAM minimum** (16GB recommended)
- **20GB free disk space**

---

## Installation

### Option 1: Automated Install (Recommended)

```bash
# Clone or download this repository
cd LocalAnalyticsLab

# Run the installer
./install.sh
```

The installer will:
- ✓ Check prerequisites (Docker, Just)
- ✓ Install Just if needed (via Homebrew)
- ✓ Create necessary directories
- ✓ Start all services
- ✓ Initialize databases and connections

### Option 2: Manual Install

```bash
# Install Just
brew install just

# Create directories
mkdir -p dags logs plugins config

# Start services
just up

# Wait ~60 seconds for initialization
```

---

## Service Access

After installation completes (wait ~60 seconds), access your services:

| Service | URL | Default Credentials |
|---------|-----|---------------------|
| **Airflow** | http://localhost:8080 | `airflow` / `airflow` |
| **Superset** | http://localhost:8088 | `admin` / `admin` |
| **Trino** | http://localhost:8082 | No auth required |
| **MinIO Console** | http://localhost:9001 | `minioadmin` / `minioadmin` |
| **Spark Master** | http://localhost:8081 | No auth required |

> ⚠️ **Security Note**: These are development credentials. Change them for any production use.

---

## What's Included

### Core Stack

| Component | Version | Purpose |
|-----------|---------|---------|
| **Apache Airflow** | 2.8.1 | Workflow orchestration |
| **Apache Spark** | 3.5.0 | Distributed data processing |
| **MinIO** | Latest | S3-compatible object storage |
| **Hive Metastore** | 4.0.0 | Table metadata management |
| **Trino** | 435 | Distributed SQL query engine |
| **Apache Superset** | Latest | BI and visualization |
| **PostgreSQL** | 15 | Airflow metadata backend |
| **MySQL** | 8.0 | Hive metastore backend |

### Optional Add-ons

#### DataHub - Data Catalog & Lineage
**Adds data discovery, governance, and metadata management**

- 📖 **Documentation**: [addons/datahub/README.md](addons/datahub/README.md)
- 🚀 **Install**: `just addon-datahub-install`
- 🌐 **Access**: http://localhost:9002 (`datahub` / `datahub`)
- 💾 **Requirements**: +4GB RAM, +10GB disk

> **When to use**: Managing multiple datasets, need data lineage, team collaboration on metadata

#### DBT Production - Multi-Environment Transformations
**Production-grade DBT with dev/prod environments + Great Expectations**

- 📖 **Documentation**: [addons/dbt-production/README.md](addons/dbt-production/README.md)
- 🚀 **Install**: `just addon-dbt-prod-install`
- 🌐 **Access**: http://localhost:8083 (Great Expectations Data Docs)
- 💾 **Requirements**: +4GB RAM, +2GB disk

> **When to use**: Learning production DBT patterns, multi-environment workflows, automated data quality testing

### Pre-Configured Integrations

✅ **Spark ↔ MinIO** - S3A filesystem configured  
✅ **Hive ↔ MinIO** - External tables on object storage  
✅ **Trino ↔ Hive** - Query engine connected to catalog  
✅ **Superset ↔ Trino** - BI tool ready to visualize  
✅ **Sample Dataset** - `analytics.employees` table loaded  

---

## Quick Start Guide

### 1. Verify Installation

```bash
# Check all services are running
just ps

# View logs if needed
just logs
```

Expected output: All services showing as "Up" or "healthy"

### 2. Test Data Pipeline

**Step 1: Test Spark → MinIO Integration**
```bash
docker-compose exec spark-master /opt/spark/bin/spark-submit /opt/spark-apps/test_spark_minio.py
```
Expected: `✓✓✓ All tests passed!`

**Step 2: Query via Trino**
```bash
docker-compose exec trino trino --execute "SELECT * FROM hive.analytics.employees LIMIT 5"
```
Expected: Table with employee data

**Step 3: Visualize in Superset**
1. Open http://localhost:8088/sqllab
2. Login: `admin` / `admin`
3. Select database: **Trino Hive**
4. Run: `SELECT * FROM analytics.employees`

**Step 4: Explore in DataHub**
1. Open http://localhost:9002
2. Login: `datahub` / `datahub`
3. Search for datasets: `employees`
4. View schema, lineage, and metadata

### 3. Create Your First DAG

```python
# dags/hello_world.py
from airflow import DAG
from airflow.operators.python import PythonOperator
from datetime import datetime

def say_hello():
    print("Hello from Local Analytics Lab!")

with DAG('hello_world', start_date=datetime(2025, 1, 1), schedule='@daily') as dag:
    PythonOperator(task_id='greet', python_callable=say_hello)
```

View at: http://localhost:8080

---

## Available Commands

```bash
# Service Management
just up              # Start core services
just up-datahub      # Start all services including DataHub add-on
just down            # Stop core services  
just down-all        # Stop all services including DataHub
just restart         # Restart all services
just ps              # Show service status
just logs [service]  # View service logs
just clean           # Stop and remove all volumes (fresh start)

# Service Shells
just airflow-shell   # Access Airflow webserver bash
just spark-shell     # Access Spark master bash
just superset-cli    # Access Superset CLI
just trino-cli       # Open Trino SQL client

# Troubleshooting
just logs-airflow    # View Airflow logs
just logs-superset   # View Superset logs
just health          # Check service health
```

For all commands: `just --list`

---

## Architecture

```
┌───────────────────────────────────────────────────────────────┐
│                   Local Analytics Lab                         │
├───────────────────────────────────────────────────────────────┤
│                                                               │
│  ┌──────────┐    ┌──────────┐         ┌──────────┐          │
│  │ Superset │    │ DataHub  │         │ Airflow  │          │
│  │  :8088   │    │  :9002   │         │  :8080   │          │
│  └────┬─────┘    └────┬─────┘         └────┬─────┘          │
│       │               │                     │                │
│       ▼               ▼                     │                │
│  ┌──────────┐    ┌─────────────┐           │                │
│  │  Trino   │───▶│ Hive        │           │                │
│  │  :8082   │    │ Metastore   │           │                │
│  └────┬─────┘    └──────┬──────┘           │                │
│       │                 │                   │                │
│       │                 │                   ▼                │
│       │                 │            ┌──────────┐            │
│       │                 │            │  Spark   │            │
│       │                 │            │  :8081   │            │
│       │                 │            └────┬─────┘            │
│       │                 │                 │                  │
│       └─────────────────┼─────────────────┘                  │
│                         ▼                                    │
│                    ┌─────────┐                               │
│                    │  MinIO  │  S3 Storage                   │
│                    │ :9000/1 │                               │
│                    └─────────┘                               │
│                                                               │
│  Supporting: PostgreSQL | MySQL | Elasticsearch | Kafka     │
└───────────────────────────────────────────────────────────────┘
```

**Data Flow:**
1. Airflow orchestrates workflows
2. Spark processes data, reads/writes to MinIO
3. Hive Metastore tracks table metadata
4. Trino queries data via Hive catalog
5. Superset visualizes results from Trino

---

## Troubleshooting

### Services Won't Start

```bash
# Check what's running
just ps

# View logs for specific service
just logs [service-name]

# Nuclear option: fresh start
just clean
just up
```

### Port Already in Use

Edit `docker-compose.yml` to change conflicting ports:
- Airflow: 8080 → 8180
- Superset: 8088 → 8188
- etc.

### Superset Database Not Showing

```bash
# Restart Superset (auto-reconfigures)
docker-compose restart superset

# Or manually add connection
docker-compose exec superset superset set-database-uri \
  -d "Trino Hive" \
  -u "trino://admin@trino:8080/hive"
```

### Out of Disk Space

```bash
# Remove unused Docker images
docker system prune -a

# Remove this lab's data volumes
just clean
```

### More Help

- Check logs: `just logs [service]`
- View detailed setup guide: `SETUP_JOURNEY.md`
- Open an issue: [GitHub Issues](https://github.com/yourusername/local-analytics-lab/issues)

---

## Data Persistence

All data persists across restarts in Docker volumes:

| Volume | Contents |
|--------|----------|
| `postgres-data` | Airflow metadata & DAG runs |
| `minio-data` | All object storage data |
| `metastore-db-data` | Hive table metadata |
| `superset-data` | Dashboards & configurations |

To start completely fresh: `just clean` (removes all volumes)

---

## Project Structure

```
LocalAnalyticsLab/
├── install.sh                 # One-command installer
├── justfile                   # Command shortcuts
├── docker-compose.yml         # Service orchestration
├── README.md                  # This file
├── SETUP_JOURNEY.md          # Detailed build documentation
├── LICENSE                    # MIT License
├── CONTRIBUTING.md           # Contribution guidelines
│
├── dags/                      # Airflow DAGs (add yours here)
├── plugins/                   # Airflow plugins
├── config/                    # Airflow configuration
├── logs/                      # Service logs
│
├── spark-apps/                # Spark applications
│   └── test_spark_minio.py   # Integration test
│
├── spark-conf/                # Spark configuration
│   └── core-site.xml         # S3A settings
│
├── spark-jars/                # Spark dependencies
│   ├── hadoop-aws-3.3.4.jar
│   └── aws-java-sdk-bundle-1.12.262.jar
│
├── hive-metastore/           # Custom Hive Metastore
│   ├── Dockerfile
│   └── [JARs and configs]
│
├── trino/                    # Trino configuration
│   ├── catalog/             # Catalog definitions
│   └── [S3A JARs]
│
└── superset-custom/          # Custom Superset image
    ├── Dockerfile
    └── requirements-local.txt
```

---

## Use Cases

### Learning & Experimentation
- Hands-on practice with modern data tools
- Test new features safely
- Learn integration patterns
- Experiment with data pipelines

### Development
- Develop and test DAGs locally
- Build Spark jobs with real infrastructure
- Design dashboards before production
- Prototype data architectures

### Demos & Training
- Showcase analytics capabilities
- Training environment for teams
- Technical demonstrations
- POC development

---

## What's Next?

### Extend Your Lab

- **Add dbt**: Transform data with SQL
- **Integrate DataHub**: Data catalog and lineage
- **Add Kafka**: Real-time streaming
- **Deploy ML Models**: MLflow integration
- **Data Quality**: Great Expectations

### Learn More

- 📖 [Detailed Setup Guide](SETUP_JOURNEY.md) - Complete build documentation
- 🎓 [Airflow Tutorial](https://airflow.apache.org/docs/apache-airflow/stable/tutorial.html)
- 📊 [Superset Documentation](https://superset.apache.org/docs/intro)
- ⚡ [Spark Programming Guide](https://spark.apache.org/docs/latest/sql-programming-guide.html)

---

## Contributing

Contributions welcome! Please read [CONTRIBUTING.md](CONTRIBUTING.md) for guidelines.

### Ways to Contribute
- 🐛 Report bugs
- 💡 Suggest features or new addons
- 📝 Improve documentation
- 🔧 Submit pull requests
- 🔌 Create new addons (see [addons/README.md](addons/README.md))
- ⭐ Star the repository

---

## License

This project is licensed under the MIT License - see [LICENSE](LICENSE) file for details.

---

## Acknowledgments

Built with:
- [Apache Airflow](https://airflow.apache.org/)
- [Apache Spark](https://spark.apache.org/)
- [MinIO](https://min.io/)
- [Apache Hive](https://hive.apache.org/)
- [Trino](https://trino.io/)
- [Apache Superset](https://superset.apache.org/)

---

## Support

- 📚 Documentation: See `SETUP_JOURNEY.md` for detailed guides
- 🐛 Issues: [GitHub Issues](https://github.com/yourusername/local-analytics-lab/issues)
- 💬 Discussions: [GitHub Discussions](https://github.com/yourusername/local-analytics-lab/discussions)

---

**Happy Data Engineering! 🚀**
