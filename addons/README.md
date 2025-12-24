# Optional Add-ons

This directory contains optional components that extend the core Local Analytics Lab functionality. Each addon is self-contained and can be installed independently.

## Available Add-ons

### 📚 DataHub - Data Catalog & Metadata Management

**What it does**: Provides data discovery, lineage tracking, and governance capabilities for your data ecosystem.

**Key Features**:
- Search and browse all datasets
- Visualize data lineage and dependencies
- Document metadata (descriptions, tags, owners)
- Track data quality metrics
- Manage access and compliance

**Installation**: See [datahub/README.md](datahub/README.md)

**Quick Start**:
```bash
just addon-datahub-install
```

**Requirements**:
- +4GB RAM
- +10GB disk space
- Core stack must be running

**When to use**:
- Managing 10+ datasets
- Multiple teams sharing data
- Need data lineage visualization
- Governance and compliance requirements

---

### 🔧 DBT Production - Multi-Environment Data Transformation

**What it does**: Production-grade DBT setup with dev/prod environments, Great Expectations validation, and automated CI/CD pipelines.

**Key Features**:
- Multi-environment architecture (dev → prod)
- Automated data quality testing (DBT + Great Expectations)
- Full CI/CD pipeline via Airflow
- Schema isolation (dev_analytics vs analytics)
- Production promotion workflows
- Interactive data quality reports

**Installation**: See [dbt-production/README.md](dbt-production/README.md)

**Quick Start**:
```bash
just addon-dbt-prod-install
```

**Requirements**:
- +4GB RAM
- +2GB disk space
- Core stack must be running
- Sample data in hive.analytics.employees

**When to use**:
- Learning production DBT patterns
- Need multi-environment setup
- Want automated testing and validation
- Building production data pipelines
- Learning CI/CD for data

**What you'll learn**:
- Real production workflows
- Data quality gates
- Environment promotion
- Automated testing
- Great Expectations validation

---

## Creating Your Own Add-ons

Want to add more components to the Local Analytics Lab? Here's the structure:

```
addons/
└── your-addon/
    ├── README.md              # Documentation
    ├── docker-compose.yml     # Service definitions
    └── config/                # Configuration files (optional)
```

### Add-on Guidelines

1. **Self-contained**: Should work independently with minimal dependencies on core stack
2. **Optional**: Core functionality should work without the addon
3. **Documented**: Include comprehensive README with installation and usage
4. **Network**: Connect to `localanalyticslab_default` network
5. **Ports**: Avoid conflicts with core services (see main README for used ports)

### Reserved Ports (Core Stack)

Don't use these ports in your addons:
- 5433 (Postgres)
- 7077 (Spark RPC)
- 8080 (Airflow)
- 8081 (Spark Master UI)
- 8082 (Trino)
- 8088 (Superset)
- 9000 (MinIO API)
- 9001 (MinIO Console)
- 9083 (Hive Metastore)
- 3307 (MySQL Hive)

### Reserved Ports (DataHub Add-on)

Avoid if user has DataHub installed:
- 3308 (DataHub MySQL)
- 8081 (Kafka Schema Registry)
- 8090 (DataHub GMS)
- 9002 (DataHub Frontend)
- 9092 (Kafka)
- 9200 (Elasticsearch)

### Example Add-on Ideas

- **Jupyter/JupyterLab**: Interactive notebooks for data exploration
- **Dagster**: Alternative workflow orchestration
- **DBT**: Transform data with SQL-based workflows
- **Apache Druid**: Real-time analytics database
- **Metabase**: Alternative BI tool
- **Apache Ranger**: Security and access control
- **Prometheus + Grafana**: Metrics and monitoring
- **Apache Atlas**: Another metadata management option

### Integration Pattern

```yaml
# your-addon/docker-compose.yml
version: '3.8'

services:
  your-service:
    image: your-image:tag
    ports:
      - "XXXX:XXXX"  # Choose unused port
    networks:
      - default
    # ... your configuration

networks:
  default:
    name: localanalyticslab_default
    external: true
```

### justfile Commands

Add commands to main `justfile`:

```just
# Your Addon: Install
addon-youraddon-install:
    docker-compose -f docker-compose.yml -f addons/youraddon/docker-compose.yml up -d

# Your Addon: Stop
addon-youraddon-stop:
    docker-compose -f addons/youraddon/docker-compose.yml stop

# Your Addon: Clean
addon-youraddon-clean:
    docker-compose -f addons/youraddon/docker-compose.yml down -v
```

## Contributing Add-ons

If you create a useful addon, please contribute it back!

1. Create addon following the guidelines above
2. Test thoroughly with core stack
3. Document clearly in README.md
4. Submit a pull request

See [CONTRIBUTING.md](../CONTRIBUTING.md) for detailed contribution guidelines.

---

## Support

- **Issues**: Open an issue on GitHub
- **Questions**: Check existing documentation first
- **Feature Requests**: Suggest new addons via GitHub issues
