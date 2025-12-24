# DataHub Addon

DataHub is an open-source metadata platform that provides data discovery, observability, and governance capabilities. This addon integrates DataHub with the Local Analytics Lab.

## What is DataHub?

DataHub helps you:
- **Discover Data**: Search and browse datasets across your data ecosystem
- **Understand Lineage**: Visualize data pipelines and dependencies
- **Document Metadata**: Add descriptions, tags, and ownership information
- **Monitor Quality**: Track data quality metrics and alerts
- **Manage Governance**: Control access and ensure compliance

## Architecture

The DataHub addon includes 7 services:

| Service | Port | Purpose |
|---------|------|---------|
| DataHub Frontend | 9002 | React-based web UI |
| DataHub GMS | 8090 | Metadata service (GraphQL API) |
| Elasticsearch | 9200 | Search and indexing engine |
| MySQL | 3308 | Metadata storage |
| Kafka Broker | 9092 | Event streaming |
| Schema Registry | 8081 | Schema management |
| Zookeeper | - | Kafka coordination |

## Prerequisites

- Core Local Analytics Lab must be running
- Additional system requirements:
  - 4GB additional RAM (DataHub requires ~3GB)
  - 10GB additional disk space

## Installation

### Quick Start

```bash
# From project root
just addon-datahub-install
```

This command:
1. Starts all 7 DataHub services
2. Waits for health checks to pass (~2-3 minutes)
3. Opens DataHub UI in your browser

### Manual Installation

```bash
# Navigate to project root
cd /path/to/LocalAnalyticsLab

# Start DataHub services
docker-compose -f docker-compose.yml -f addons/datahub/docker-compose.yml up -d

# Check status
docker-compose -f addons/datahub/docker-compose.yml ps

# Wait for all services to be healthy
docker-compose -f addons/datahub/docker-compose.yml ps | grep healthy
```

## Access DataHub

Once all services are healthy:

**DataHub UI**: http://localhost:9002

**Default credentials**:
- Username: `datahub`
- Password: `datahub`

## Verify Installation

```bash
# Check DataHub GMS health
curl http://localhost:8090/health

# Check Elasticsearch
curl http://localhost:9200/_cluster/health

# Check Schema Registry
curl http://localhost:8081/
```

## Integration with Analytics Lab

DataHub can catalog and monitor:

### 1. MinIO/S3 Data
```bash
# Install MinIO connector
pip install acryl-datahub[minio]

# Ingest MinIO metadata
datahub ingest -c datahub-minio-recipe.yml
```

### 2. Trino Queries
```bash
# Install Trino connector
pip install acryl-datahub[trino]

# Ingest Trino tables
datahub ingest -c datahub-trino-recipe.yml
```

### 3. Airflow DAGs
```bash
# Install Airflow connector
pip install acryl-datahub[airflow]

# Configure Airflow lineage
# Add to airflow.cfg:
# [lineage]
# backend = datahub_provider.lineage.datahub.DatahubLineageBackend
```

## Sample Ingestion Recipes

### MinIO Recipe (`datahub-minio-recipe.yml`)
```yaml
source:
  type: s3
  config:
    aws_endpoint_url: http://minio:9000
    aws_access_key_id: minioadmin
    aws_secret_access_key: minioadmin
    path_specs:
      - include: "s3://warehouse/*"

sink:
  type: datahub-rest
  config:
    server: http://datahub-gms:8080
```

### Trino Recipe (`datahub-trino-recipe.yml`)
```yaml
source:
  type: trino
  config:
    host_port: trino:8080
    database: hive
    username: admin
    catalog: hive
    schema_pattern:
      allow:
        - analytics

sink:
  type: datahub-rest
  config:
    server: http://datahub-gms:8080
```

## Usage Examples

### Search for Datasets
1. Open http://localhost:9002
2. Click search bar at top
3. Enter table name (e.g., "employees")
4. Browse metadata, schema, and lineage

### Add Documentation
1. Navigate to a dataset
2. Click "Add Documentation"
3. Enter description in Markdown
4. Save changes

### View Lineage
1. Open a dataset
2. Click "Lineage" tab
3. Explore upstream/downstream dependencies
4. Visualize data flow

## Common Commands

```bash
# Start DataHub addon
just addon-datahub-install

# Stop DataHub addon
just addon-datahub-stop

# View DataHub logs
just addon-datahub-logs

# Restart DataHub
just addon-datahub-restart

# Remove DataHub (keeps data)
just addon-datahub-down

# Remove DataHub and data
just addon-datahub-clean
```

## Troubleshooting

### Services won't start
```bash
# Check Docker resources
docker system df

# Free up space
docker system prune

# Check service logs
docker-compose -f addons/datahub/docker-compose.yml logs datahub-gms
```

### Elasticsearch heap size errors
```bash
# Reduce heap size in docker-compose.yml
# Change ES_JAVA_OPTS=-Xms512m -Xmx512m
# To ES_JAVA_OPTS=-Xms256m -Xmx256m
```

### Frontend not loading
```bash
# Check GMS is healthy
curl http://localhost:8090/health

# Restart frontend
docker-compose -f addons/datahub/docker-compose.yml restart datahub-frontend
```

### Can't connect to Kafka
```bash
# Verify Kafka is running
docker-compose -f addons/datahub/docker-compose.yml ps datahub-broker

# Check Kafka logs
docker-compose -f addons/datahub/docker-compose.yml logs datahub-broker
```

## Uninstall

### Keep data (can restart later)
```bash
just addon-datahub-down
```

### Remove completely (deletes all metadata)
```bash
just addon-datahub-clean

# Or manually
docker-compose -f addons/datahub/docker-compose.yml down -v
```

## Resources

- **DataHub Docs**: https://datahubproject.io/docs
- **Ingestion Sources**: https://datahubproject.io/docs/metadata-ingestion
- **API Reference**: https://datahubproject.io/docs/api/graphql/overview
- **Community Slack**: https://slack.datahubproject.io

## Performance Tuning

### For 8GB RAM systems
```yaml
# In docker-compose.yml, reduce memory:
datahub-elasticsearch:
  environment:
    - ES_JAVA_OPTS=-Xms256m -Xmx256m

datahub-frontend:
  environment:
    - JAVA_OPTS=-Xms256m -Xmx256m ...

datahub-broker:
  environment:
    - KAFKA_HEAP_OPTS=-Xms128m -Xmx128m
```

### For production use
```yaml
# Increase replicas and resources
datahub-elasticsearch:
  environment:
    - ES_JAVA_OPTS=-Xms2g -Xmx2g
  deploy:
    replicas: 3

datahub-broker:
  environment:
    - KAFKA_OFFSETS_TOPIC_REPLICATION_FACTOR=3
```

## Contributing

DataHub addon improvements:
- Add more ingestion recipes (Postgres, MySQL, etc.)
- Create sample dashboards for metadata monitoring
- Document best practices for metadata management
- Add automated metadata quality checks

See main [CONTRIBUTING.md](../../CONTRIBUTING.md) for guidelines.
