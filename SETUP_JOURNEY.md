# Local Analytics Lab - Build Journey & Learnings

This document chronicles the complete journey of building a local analytics playground from scratch, including all challenges faced and solutions discovered.

## Table of Contents
1. [Initial Goal](#initial-goal)
2. [Architecture Overview](#architecture-overview)
3. [Build Timeline](#build-timeline)
4. [Key Learnings](#key-learnings)
5. [Troubleshooting Guide](#troubleshooting-guide)
6. [Production Considerations](#production-considerations)

---

## Initial Goal

Build a complete local analytics stack for learning and experimentation with:
- Data orchestration (Airflow)
- Object storage (MinIO as S3)
- Data processing (Spark)
- Metadata management (Hive Metastore)
- Query engine (Trino)
- Visualization (Superset)

**Target**: Everything running in Docker with persistent storage and automated setup.

---

## Architecture Overview

```
┌─────────────────────────────────────────────────────────────────┐
│                     Local Analytics Lab                         │
├─────────────────────────────────────────────────────────────────┤
│                                                                 │
│  ┌──────────┐                                   ┌───────────┐  │
│  │ Superset │ ← BI Layer                        │  Airflow  │  │
│  │  :8088   │                                   │   :8080   │  │
│  └────┬─────┘                                   └─────┬─────┘  │
│       │                                               │        │
│       ▼                                               │        │
│  ┌──────────┐                                        │        │
│  │  Trino   │ ← Query Engine                         │        │
│  │  :8082   │                                        │        │
│  └────┬─────┘                                        │        │
│       │                                              │        │
│       ▼                                              ▼        │
│  ┌─────────────────┐                           ┌─────────┐   │
│  │ Hive Metastore  │ ← Metadata Layer          │  Spark  │   │
│  │     :9083       │                           │  :8081  │   │
│  └────┬────────────┘                           └────┬────┘   │
│       │                                             │        │
│       │            ┌──────────┐                    │        │
│       └───────────►│  MinIO   │◄───────────────────┘        │
│                    │ :9000/01 │ ← Storage Layer             │
│                    └──────────┘                              │
│                                                               │
│  ┌──────────────────────────────────────────────────────┐   │
│  │ Supporting Services:                                  │   │
│  │ • PostgreSQL :5433 (Airflow metadata)                │   │
│  │ • MySQL :3307 (Hive metadata)                        │   │
│  │ • Fake GCS :4443 (optional GCS emulation)           │   │
│  └──────────────────────────────────────────────────────┘   │
└─────────────────────────────────────────────────────────────────┘
```

**Data Flow Example:**
1. Airflow orchestrates a workflow
2. Spark reads from MinIO, processes data, writes back
3. Hive Metastore tracks table metadata
4. Trino queries data via Hive catalog
5. Superset visualizes results from Trino

---

## Build Timeline

### Phase 1: Foundation (Airflow + PostgreSQL)
**Goal**: Get basic orchestration running

**Steps:**
1. Created docker-compose.yml with Airflow + PostgreSQL
2. Used LocalExecutor (simpler than CeleryExecutor for local dev)
3. Created justfile for command shortcuts
4. Set up persistent volumes for metadata

**Port Assignments:**
- Airflow: 8080
- PostgreSQL: 5433 (changed from 5432 to avoid conflicts)

**Lessons:**
- Use LocalExecutor for simplicity in local environments
- Always use named volumes for persistence
- Justfile is invaluable for complex Docker setups

### Phase 2: Storage Layer (MinIO)
**Goal**: Add S3-compatible object storage

**Steps:**
1. Added MinIO service to docker-compose
2. Created init script to create default bucket
3. Set up MinIO client (mc) for bucket operations

**Port Assignments:**
- MinIO API: 9000
- MinIO Console: 9001

**Lessons:**
- MinIO is an excellent S3 replacement for local dev
- Use `path.style.access=true` for S3A compatibility
- Create buckets automatically via entrypoint script

**Configuration Pattern:**
```yaml
services:
  minio:
    environment:
      MINIO_ROOT_USER: minioadmin
      MINIO_ROOT_PASSWORD: minioadmin
    command: server /data --console-address ":9001"
```

### Phase 3: Data Processing (Spark)
**Goal**: Add distributed processing engine

**Steps:**
1. Added Spark master and worker services
2. Configured S3A filesystem support
3. Created core-site.xml for MinIO connection
4. Downloaded required JARs: hadoop-aws, aws-java-sdk-bundle

**Challenges:**
- **ClassNotFoundException for S3A classes**: Spark docker image doesn't include S3A dependencies
- **Solution**: Downloaded JARs manually and copied to Spark containers
  ```bash
  # hadoop-aws-3.3.4.jar
  # aws-java-sdk-bundle-1.12.262.jar
  ```

**Port Assignments:**
- Spark Master UI: 8081 (changed from 8080)
- Spark Master RPC: 7077

**Configuration Files:**
```xml
<!-- spark-conf/core-site.xml -->
<configuration>
  <property>
    <name>fs.s3a.endpoint</name>
    <value>http://minio:9000</value>
  </property>
  <property>
    <name>fs.s3a.access.key</name>
    <value>minioadmin</value>
  </property>
  <property>
    <name>fs.s3a.secret.key</name>
    <value>minioadmin</value>
  </property>
  <property>
    <name>fs.s3a.path.style.access</name>
    <value>true</value>
  </property>
  <property>
    <name>fs.s3a.impl</name>
    <value>org.apache.hadoop.fs.s3a.S3AFileSystem</value>
  </property>
</configuration>
```

**Testing:**
Created test_spark_minio.py to verify:
```python
from pyspark.sql import SparkSession
# Write Parquet to MinIO
# Read back and verify
```

**Lessons:**
- Docker images often lack S3A support by default
- Version compatibility matters: Hadoop 3.3.4 + AWS SDK 1.12.x
- Always test write → read cycles
- Mount configuration files as read-only volumes

### Phase 4: Metadata Layer (Hive Metastore)
**Goal**: Add metadata management for tables

**Steps:**
1. Added MySQL service for Hive metadata storage
2. Created custom Hive Metastore Dockerfile
3. Added mysql-connector JDBC driver
4. Configured metastore to use MySQL backend
5. Added S3A JARs to Hive Metastore

**Challenges:**
- **JDBC driver missing**: Hive needs MySQL connector JAR
- **S3A support needed**: Metastore needs same S3A JARs as Spark
- **Solution**: Created custom Dockerfile with all dependencies

**Custom Dockerfile:**
```dockerfile
FROM apache/hive:4.0.0
USER root

# Copy MySQL JDBC driver
COPY mysql-connector-j-8.0.33.jar /opt/hive/lib/

# Copy S3A JARs (same versions as Spark)
COPY hadoop-aws-3.3.4.jar /opt/hive/lib/
COPY aws-java-sdk-bundle-1.12.262.jar /opt/hive/lib/

# Copy S3A configuration
COPY core-site.xml /opt/hadoop/etc/hadoop/

USER hive
```

**Port Assignments:**
- Hive Metastore: 9083 (Thrift)
- MySQL: 3307 (changed from 3306)

**Configuration:**
```yaml
environment:
  SERVICE_NAME: metastore
  DB_DRIVER: mysql
  SERVICE_OPTS: >-
    -Djavax.jdo.option.ConnectionDriverName=com.mysql.cj.jdbc.Driver
    -Djavax.jdo.option.ConnectionURL=jdbc:mysql://metastore-db:3306/metastore
    -Djavax.jdo.option.ConnectionUserName=hive
    -Djavax.jdo.option.ConnectionPassword=hive
```

**Lessons:**
- Custom Dockerfiles are necessary for complex dependencies
- Keep S3A JAR versions consistent across services
- Use separate database for Hive metadata (not shared with Airflow)
- Mount core-site.xml in both Spark and Hive for consistency

### Phase 5: Query Engine (Trino)
**Goal**: Add distributed SQL query engine

**Steps:**
1. Added Trino service
2. Created Hive catalog configuration
3. Added S3A JARs to Trino's Hive plugin directory
4. Configured connection to Hive Metastore

**Challenges:**
- **S3A ClassNotFoundException in Trino**: Even with Hive Metastore configured
- **Solution**: Mount S3A JARs directly in Trino's plugin directory

**Port Assignments:**
- Trino: 8082 (changed from 8080)

**Catalog Configuration:**
```properties
# trino/catalog/hive.properties
connector.name=hive
hive.metastore.uri=thrift://hive-metastore:9083
hive.s3.endpoint=http://minio:9000
hive.s3.path-style-access=true
hive.s3.aws-access-key=minioadmin
hive.s3.aws-secret-key=minioadmin
```

**Volume Mounts:**
```yaml
volumes:
  - ./trino/catalog:/etc/trino/catalog
  - ./hadoop-aws-3.3.4.jar:/usr/lib/trino/plugin/hive/hadoop-aws-3.3.4.jar
  - ./aws-java-sdk-bundle-1.12.262.jar:/usr/lib/trino/plugin/hive/aws-java-sdk-bundle-1.12.262.jar
```

**Testing:**
```sql
-- Create schema
CREATE SCHEMA IF NOT EXISTS hive.analytics 
WITH (location = 's3a://analytics/warehouse/');

-- Query data
SELECT * FROM hive.analytics.employees LIMIT 10;
```

**Lessons:**
- Trino needs JARs in specific plugin directories
- Hive catalog configuration is separate from Metastore config
- Use `path-style-access=true` for MinIO compatibility
- Test with `SHOW CATALOGS` and `SHOW SCHEMAS` first

### Phase 6: Visualization (Superset)
**Goal**: Add BI and visualization layer

**Steps:**
1. Added Superset service
2. Attempted to install Trino driver
3. Multiple failed attempts with different approaches
4. Finally discovered correct solution

**The Great Superset Driver Saga:**

**Attempt 1: Runtime pip install**
```bash
docker-compose exec superset pip install trino sqlalchemy-trino
```
- ❌ Failed: Installed to user site-packages, not venv
- Issue: Superset uses venv at `/app/.venv/`

**Attempt 2: requirements-local.txt with bootstrap**
- Created requirements-local.txt
- Expected bootstrap script to install automatically
- ❌ Failed: Bootstrap runs as superset user, no write access to venv

**Attempt 3: Dockerfile with uv package manager**
```dockerfile
RUN uv pip install trino sqlalchemy-trino
```
- ❌ Failed: Permission denied on venv directory
- Fixed: Added `USER root` before install
- ❌ Still failed: `sqlalchemy-trino` package had broken/incomplete installation

**Attempt 4: Dockerfile with pip --target**
```dockerfile
USER root
RUN pip install --target=/app/.venv/lib/python3.10/site-packages \
    trino sqlalchemy-trino
```
- ❌ Failed: `sqlalchemy-trino` still only created dist-info, no actual code

**Attempt 5: Discovery and Success**
- Investigated: `trino` package itself includes SQLAlchemy dialect!
- Location: `trino.sqlalchemy.dialect.TrinoDialect`
- No need for separate `sqlalchemy-trino` package

**Final Working Solution:**
```dockerfile
FROM apache/superset:latest
USER root
COPY requirements-local.txt /tmp/requirements-local.txt
RUN pip install --target=/app/.venv/lib/python3.10/site-packages \
    --no-cache-dir -r /tmp/requirements-local.txt
USER superset
```

```txt
# requirements-local.txt
trino>=0.328.0
```

**Authentication Challenge:**
- Initial connection: `trino://trino:8080/hive`
- ❌ Error: `401: Basic authentication or X-Trino-User must be sent`
- ✅ Solution: `trino://admin@trino:8080/hive`

**Automated Setup:**
Created `superset-init.sh`:
```bash
#!/bin/bash
superset db upgrade
superset fab create-admin \
    --username admin \
    --password admin \
    --email admin@superset.com
superset init
superset set-database-uri \
    -d "Trino Hive" \
    -u "trino://admin@trino:8080/hive"
```

**Port Assignments:**
- Superset: 8088

**Lessons:**
- Always check if packages include their own dialect implementations
- `sqlalchemy-trino` was a red herring - buggy and unnecessary
- Superset uses venv, requires root for pip install during build
- Use `--target` to install directly into venv
- Trino requires username in connection string (any username works)
- Automate database configuration via init scripts
- Mount init script and run before starting server

---

## Key Learnings

### Docker & Networking

1. **Port Conflicts**: Changed default ports to avoid conflicts
   - PostgreSQL: 5433 (not 5432)
   - MySQL: 3307 (not 3306)
   - Spark: 8081 (not 8080)
   - Trino: 8082 (not 8080)

2. **Service Discovery**: Use service names as hostnames
   ```yaml
   # Services can reach each other by name
   - minio (not localhost:9000)
   - trino (not localhost:8082)
   ```

3. **Volume Persistence**: Always use named volumes
   ```yaml
   volumes:
     postgres-data:
     minio-data:
     metastore-db-data:
     superset-data:
   ```

4. **Healthchecks**: Critical for dependent services
   ```yaml
   healthcheck:
     test: ["CMD", "curl", "-f", "http://localhost:8088/health"]
     interval: 30s
     timeout: 10s
     retries: 3
   ```

### JAR Management

1. **Version Compatibility Matrix**:
   ```
   Hadoop 3.3.4
   ├── hadoop-aws-3.3.4.jar
   └── aws-java-sdk-bundle-1.12.262.jar (not 1.12.x > 300)
   
   Spark 3.5.0 → Compatible with Hadoop 3.3.x
   Hive 4.0.0 → Compatible with Hadoop 3.3.x
   ```

2. **Deployment Pattern**:
   - Download JARs once
   - Copy to all services that need S3A
   - Mount as volumes or COPY in Dockerfile

3. **Locations**:
   - Spark: `/opt/spark/jars/`
   - Hive: `/opt/hive/lib/`
   - Trino: `/usr/lib/trino/plugin/hive/`

### Configuration Management

1. **core-site.xml Pattern**:
   - Create once
   - Mount read-only in all services
   - Consistent S3A configuration everywhere

2. **Dockerfile vs Volume Mounts**:
   - **Dockerfile**: For dependencies that rarely change (JARs, packages)
   - **Volume Mounts**: For configs that may need editing (catalogs, core-site.xml)

3. **Environment Variables**:
   - Use for credentials and connection strings
   - Override defaults without rebuilding images

### Python Package Management

1. **Superset Venv Pattern**:
   ```dockerfile
   # Install to venv during build
   USER root
   RUN pip install --target=/app/.venv/lib/python3.10/site-packages package
   USER superset
   ```

2. **Check Package Contents**:
   ```bash
   # Before installing, verify package structure
   pip download package
   tar -tzf package.whl | head
   ```

3. **Dialect Discovery**:
   ```python
   # Test if dialect is available
   from sqlalchemy import create_engine
   engine = create_engine('trino://host:port/catalog')
   ```

### S3A Configuration

**Required Properties**:
```xml
fs.s3a.endpoint           # MinIO endpoint
fs.s3a.access.key         # Access key
fs.s3a.secret.key         # Secret key
fs.s3a.path.style.access  # true for MinIO
fs.s3a.impl               # S3AFileSystem class
```

**Common Mistakes**:
- ❌ Using `http://localhost:9000` (use service name)
- ❌ Missing `path.style.access=true`
- ❌ Wrong AWS SDK version
- ❌ JARs in wrong directory

### Automation & Reproducibility

1. **Init Scripts**:
   - Run idempotently (safe to run multiple times)
   - Use `|| echo "already exists"` pattern
   - Mount as read-only

2. **Justfile Benefits**:
   - Single source of truth for commands
   - Easy onboarding for new developers
   - Consistent command interface

3. **README Requirements**:
   - Prerequisites clearly listed
   - Port numbers documented
   - Default credentials provided
   - Test commands included

---

## Troubleshooting Guide

### Services Won't Start

```bash
# Check what's running
docker-compose ps

# View logs
docker-compose logs -f [service-name]

# Check port conflicts
lsof -i :8080  # Find what's using port 8080

# Nuclear option: clean restart
just clean
just up
```

### S3A ClassNotFoundException

**Symptoms**: `java.lang.ClassNotFoundException: org.apache.hadoop.fs.s3a.S3AFileSystem`

**Solutions**:
1. Verify JARs exist:
   ```bash
   docker-compose exec spark-master ls -la /opt/spark/jars/ | grep -E 'hadoop-aws|aws-java-sdk'
   ```

2. Check versions match:
   ```bash
   # Hadoop 3.3.4 requires AWS SDK 1.12.x (< 300)
   ```

3. Verify core-site.xml is mounted:
   ```bash
   docker-compose exec spark-master cat /opt/hadoop/etc/hadoop/core-site.xml
   ```

### Superset Driver Not Loading

**Symptoms**: `Can't load plugin: sqlalchemy.dialects:trino`

**Solutions**:
1. Check if installed in venv:
   ```bash
   docker-compose exec superset python -c "import trino.sqlalchemy; print('OK')"
   ```

2. Verify package in correct location:
   ```bash
   docker-compose exec superset ls /app/.venv/lib/python3.10/site-packages/ | grep trino
   ```

3. Rebuild image:
   ```bash
   docker-compose down superset
   docker-compose build --no-cache superset
   docker-compose up -d superset
   ```

### Trino Can't Connect to Hive

**Symptoms**: Trino shows only `system` catalog

**Solutions**:
1. Check Hive Metastore is running:
   ```bash
   docker-compose ps hive-metastore
   ```

2. Verify catalog configuration:
   ```bash
   docker-compose exec trino cat /etc/trino/catalog/hive.properties
   ```

3. Check Metastore connectivity:
   ```bash
   docker-compose exec trino curl -v telnet://hive-metastore:9083
   ```

4. View Trino logs:
   ```bash
   docker-compose logs -f trino | grep -i hive
   ```

### MinIO Connection Refused

**Symptoms**: `Connection refused` when accessing MinIO

**Solutions**:
1. Use service name, not localhost:
   ```python
   # ✓ Correct
   endpoint = "http://minio:9000"
   
   # ✗ Wrong (from container)
   endpoint = "http://localhost:9000"
   ```

2. Check MinIO is healthy:
   ```bash
   docker-compose exec minio mc alias set local http://localhost:9000 minioadmin minioadmin
   docker-compose exec minio mc ls local
   ```

3. Verify path-style access:
   ```xml
   <property>
     <name>fs.s3a.path.style.access</name>
     <value>true</value>  <!-- Must be true for MinIO -->
   </property>
   ```

### Database Connection Issues

**Symptoms**: Can't connect to PostgreSQL/MySQL

**Solutions**:
1. Check ports are correct:
   - PostgreSQL: 5433 (not 5432)
   - MySQL: 3307 (not 3306)

2. Wait for healthcheck:
   ```bash
   docker-compose ps | grep healthy
   ```

3. Test connection:
   ```bash
   # PostgreSQL
   docker-compose exec postgres psql -U airflow -d airflow -c "SELECT 1;"
   
   # MySQL
   docker-compose exec metastore-db mysql -u hive -phive -e "SHOW DATABASES;"
   ```

---

## Production Considerations

### What Would Need to Change

1. **Security**:
   - [ ] Change all default passwords
   - [ ] Use secrets management (Docker secrets, Vault)
   - [ ] Enable SSL/TLS everywhere
   - [ ] Implement proper authentication (LDAP, OAuth)
   - [ ] Network isolation and firewall rules

2. **High Availability**:
   - [ ] Multiple Airflow schedulers
   - [ ] Spark in cluster mode
   - [ ] Trino coordinator + workers
   - [ ] MinIO distributed mode
   - [ ] PostgreSQL with replication
   - [ ] Load balancers

3. **Scalability**:
   - [ ] Kubernetes instead of Docker Compose
   - [ ] Auto-scaling workers
   - [ ] Separate compute and storage
   - [ ] Distributed caching (Redis)
   - [ ] Resource quotas and limits

4. **Monitoring**:
   - [ ] Prometheus + Grafana
   - [ ] Log aggregation (ELK stack)
   - [ ] Distributed tracing (Jaeger)
   - [ ] Alerting (PagerDuty, Slack)
   - [ ] SLA monitoring

5. **Data Management**:
   - [ ] Backup and disaster recovery
   - [ ] Data lifecycle policies
   - [ ] Schema evolution strategy
   - [ ] Data quality monitoring
   - [ ] Metadata governance

6. **Performance**:
   - [ ] Query result caching
   - [ ] Materialized views
   - [ ] Partition pruning
   - [ ] Column-based formats (Parquet, ORC)
   - [ ] Cost-based optimization

### Local vs Production Gap

| Aspect | Local Setup | Production |
|--------|-------------|------------|
| Storage | Single MinIO instance | Distributed MinIO or S3 |
| Compute | Single Spark worker | Spark cluster (10-100s nodes) |
| Database | SQLite/MySQL | PostgreSQL with replication |
| Security | Default passwords | Secrets management, SSO |
| Networking | Docker bridge | VPCs, private subnets, VPNs |
| Monitoring | Docker logs | Full observability stack |
| Cost | Free | $$$$ (optimize for cost) |

---

## Sample Workflows

### End-to-End Data Pipeline

```python
# dags/analytics_pipeline.py
from airflow import DAG
from airflow.providers.apache.spark.operators.spark_submit import SparkSubmitOperator
from datetime import datetime, timedelta

default_args = {
    'owner': 'analytics',
    'start_date': datetime(2025, 1, 1),
    'retries': 2,
    'retry_delay': timedelta(minutes=5),
}

with DAG(
    'daily_analytics_pipeline',
    default_args=default_args,
    schedule_interval='@daily',
    catchup=False,
) as dag:
    
    # Step 1: Extract and transform data with Spark
    process_data = SparkSubmitOperator(
        task_id='process_raw_data',
        application='/opt/spark/apps/process_analytics.py',
        conf={
            'spark.hadoop.fs.s3a.endpoint': 'http://minio:9000',
            'spark.hadoop.fs.s3a.access.key': 'minioadmin',
            'spark.hadoop.fs.s3a.secret.key': 'minioadmin',
            'spark.hadoop.fs.s3a.path.style.access': 'true',
        },
        packages='org.apache.hadoop:hadoop-aws:3.3.4,com.amazonaws:aws-java-sdk-bundle:1.12.262',
    )
    
    # Step 2: Query via Trino (validation)
    # Step 3: Refresh Superset cache
    # etc.
```

### Spark Processing Job

```python
# process_analytics.py
from pyspark.sql import SparkSession

spark = SparkSession.builder \
    .appName("Analytics Pipeline") \
    .getOrCreate()

# Read from MinIO
df = spark.read.parquet("s3a://raw-data/events/")

# Transform
transformed = df \
    .filter(df.event_type == "purchase") \
    .groupBy("user_id", "date") \
    .agg({"amount": "sum"})

# Write back to MinIO (partitioned by date)
transformed.write \
    .mode("overwrite") \
    .partitionBy("date") \
    .parquet("s3a://analytics/warehouse/purchases/")

spark.stop()
```

### Trino Query for Dashboard

```sql
-- Query aggregated data via Trino for Superset
SELECT 
    date_trunc('month', date) as month,
    COUNT(DISTINCT user_id) as active_users,
    SUM(sum_amount) as total_revenue
FROM hive.analytics.purchases
WHERE date >= current_date - interval '6' month
GROUP BY 1
ORDER BY 1 DESC;
```

---

## Resources & References

### Documentation
- [Apache Airflow](https://airflow.apache.org/docs/)
- [Apache Spark](https://spark.apache.org/docs/latest/)
- [MinIO](https://min.io/docs/minio/linux/index.html)
- [Hive](https://hive.apache.org/)
- [Trino](https://trino.io/docs/current/)
- [Superset](https://superset.apache.org/docs/intro)

### Key GitHub Issues Referenced
- Hadoop AWS S3A compatibility
- Trino Hive connector configuration
- Superset database driver installation

### Versions Used
```
Airflow: 2.8.1
Spark: 3.5.0
MinIO: latest (RELEASE.2024-12-18)
Hive: 4.0.0
Trino: 435
Superset: latest (4.1.1)
PostgreSQL: 15
MySQL: 8.0
Python: 3.10/3.12
```

---

## Future Enhancements

### Planned
- [ ] DataHub integration for data catalog
- [ ] dbt for data transformations
- [ ] Great Expectations for data quality
- [ ] Delta Lake for ACID transactions
- [ ] Iceberg table format support
- [ ] Ranger for access control
- [ ] Sample DAGs for common patterns

### Under Consideration
- [ ] Jupyter notebooks integration
- [ ] ML model training pipeline (MLflow)
- [ ] Real-time streaming (Kafka + Flink)
- [ ] Data versioning (lakeFS)
- [ ] Query federation (Dremio)

---

## Conclusion

Building this local analytics lab was a journey through:
- Docker networking and service orchestration
- JAR dependency hell and resolution
- Python package management complexities
- S3A configuration intricacies
- Service authentication patterns

**Key Success Factors:**
1. Systematic debugging (logs, test scripts, minimal reproductions)
2. Version compatibility awareness
3. Reading source code when docs fail
4. Testing each component in isolation
5. Documenting everything for reproducibility

**Time Investment:**
- Initial setup: ~4 hours
- Debugging Spark S3A: ~2 hours
- Hive Metastore integration: ~2 hours
- Trino configuration: ~1 hour
- Superset driver saga: ~3 hours
- Documentation and polish: ~2 hours
- **Total: ~14 hours**

**Result**: A fully functional, reproducible local analytics environment that works out of the box on any Mac with Docker Desktop installed.

The journey taught more than any tutorial could - real-world integration challenges, debugging strategies, and the importance of automation for complex systems.

---

*Last Updated: December 24, 2025*
*System: macOS 15.3.1, Apple M4 Pro, 48GB RAM*
