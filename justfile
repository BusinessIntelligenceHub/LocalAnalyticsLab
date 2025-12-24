# Default recipe to display available commands
default:
    @just --list

# Initialize Airflow directories
init:
    mkdir -p dags logs plugins config
    echo "Directories created: dags, logs, plugins, config"

# Start all services
up:
    docker-compose up -d
    @echo "All services starting..."
    @echo "Airflow WebUI: http://localhost:8080 (airflow/airflow)"
    @echo "Superset: http://localhost:8088 (admin/admin)"
    @echo "Trino: http://localhost:8082"
    @echo "MinIO Console: http://localhost:9001 (minioadmin/minioadmin)"
    @echo "Spark Master: http://localhost:8081"
    @echo ""
    @echo "Optional: Install DataHub addon with 'just addon-datahub-install'"

# Start all services (core stack only)
up-all: up

# Alias for backward compatibility
start: up

# Stop all services
down:
    docker-compose down

# Alias for backward compatibility  
stop: down

# Stop and remove all volumes (clean slate)
clean:
    docker-compose down -v
    @echo "All services stopped and volumes removed"

# ============================================
# DataHub Add-on Commands
# ============================================

# DataHub: Install and start addon
addon-datahub-install:
    @echo "Starting DataHub addon (requires core stack running)..."
    @echo "This will take 2-3 minutes for all services to become healthy."
    docker-compose -f docker-compose.yml -f addons/datahub/docker-compose.yml up -d
    @echo ""
    @echo "Waiting for DataHub services to start..."
    @sleep 10
    @echo ""
    @echo "DataHub services starting. Check status with: just addon-datahub-status"
    @echo "Once healthy, access DataHub at: http://localhost:9002 (datahub/datahub)"

# DataHub: Check status
addon-datahub-status:
    @echo "=== DataHub Services Status ==="
    docker-compose -f addons/datahub/docker-compose.yml ps

# DataHub: Stop addon (keeps data)
addon-datahub-stop:
    docker-compose -f addons/datahub/docker-compose.yml stop
    @echo "DataHub addon stopped (data preserved)"

# DataHub: Start addon (if previously stopped)
addon-datahub-start:
    docker-compose -f addons/datahub/docker-compose.yml start
    @echo "DataHub addon starting..."

# DataHub: Restart addon
addon-datahub-restart:
    docker-compose -f addons/datahub/docker-compose.yml restart
    @echo "DataHub addon restarting..."

# DataHub: Remove addon (keeps data)
addon-datahub-down:
    docker-compose -f addons/datahub/docker-compose.yml down
    @echo "DataHub addon removed (data preserved in volumes)"

# DataHub: Remove addon and all data
addon-datahub-clean:
    docker-compose -f addons/datahub/docker-compose.yml down -v
    @echo "DataHub addon and all data removed"

# DataHub: View logs
addon-datahub-logs:
    docker-compose -f addons/datahub/docker-compose.yml logs -f datahub-frontend datahub-gms

# DataHub: Open UI in browser
addon-datahub-ui:
    @echo "Opening DataHub at http://localhost:9002"
    @echo "Username: datahub"
    @echo "Password: datahub"
    open http://localhost:9002

# DataHub: Access GMS CLI
addon-datahub-cli:
    docker-compose -f addons/datahub/docker-compose.yml exec datahub-gms bash

# ============================================
# End DataHub Add-on Commands
# ============================================


# View logs for all services
logs:
    docker-compose logs -f

# View logs for specific service
logs-webserver:
    docker-compose logs -f airflow-webserver

logs-scheduler:
    docker-compose logs -f airflow-scheduler

logs-postgres:
    docker-compose logs -f postgres

# Restart all services
restart:
    docker-compose restart

# Restart specific service
restart-webserver:
    docker-compose restart airflow-webserver

restart-scheduler:
    docker-compose restart airflow-scheduler

# Check status of services
ps:
    docker-compose ps

# Alias for backward compatibility
status: ps

# Access Airflow CLI
cli *ARGS:
    docker-compose run --rm airflow-cli {{ ARGS }}

# Execute bash in webserver container
airflow-shell:
    docker-compose exec airflow-webserver bash

# Alias for backward compatibility
shell: airflow-shell

# Install additional Python packages
install-packages PACKAGES:
    docker-compose exec airflow-webserver pip install {{ PACKAGES }}

# Trigger a DAG
trigger DAG_ID:
    docker-compose exec airflow-webserver airflow dags trigger {{ DAG_ID }}

# List all DAGs
list-dags:
    docker-compose exec airflow-webserver airflow dags list

# Test a task
test-task DAG_ID TASK_ID DATE:
    docker-compose exec airflow-webserver airflow tasks test {{ DAG_ID }} {{ TASK_ID }} {{ DATE }}

# Full setup (init + start)
setup: init up

# Health check
health:
    @echo "Checking service health..."
    @curl -s http://localhost:8080/health || echo "Webserver not ready yet"

# Start MinIO only
start-minio:
    docker-compose up -d minio
    @echo "MinIO started"
    @echo "Console: http://localhost:9001"
    @echo "API: http://localhost:9000"
    @echo "Username: minioadmin"
    @echo "Password: minioadmin"

# Start Fake GCS Server (manual launch)
start-gcs:
    docker-compose --profile gcs up -d fake-gcs
    @echo "Fake GCS Server started at http://localhost:4443"

# Stop Fake GCS Server
stop-gcs:
    docker-compose --profile gcs stop fake-gcs

# Create MinIO bucket
create-bucket BUCKET_NAME:
    docker-compose exec minio mc alias set local http://localhost:9000 minioadmin minioadmin
    docker-compose exec minio mc mb local/{{ BUCKET_NAME }} || echo "Bucket may already exist"
    @echo "Bucket {{ BUCKET_NAME }} created"

# List MinIO buckets
list-buckets:
    docker-compose exec minio mc alias set local http://localhost:9000 minioadmin minioadmin
    docker-compose exec minio mc ls local

# Spark: Submit a job
spark-submit APP_PATH *ARGS:
    docker-compose exec spark-master spark-submit \
        --master spark://spark-master:7077 \
        --conf spark.hadoop.fs.s3a.endpoint=http://minio:9000 \
        --conf spark.hadoop.fs.s3a.access.key=minioadmin \
        --conf spark.hadoop.fs.s3a.secret.key=minioadmin \
        --conf spark.hadoop.fs.s3a.path.style.access=true \
        --conf spark.hadoop.fs.s3a.impl=org.apache.hadoop.fs.s3a.S3AFileSystem \
        {{ APP_PATH }} {{ ARGS }}

# Spark: Open PySpark shell
spark-shell:
    docker-compose exec spark-master pyspark \
        --master spark://spark-master:7077 \
        --conf spark.hadoop.fs.s3a.endpoint=http://minio:9000 \
        --conf spark.hadoop.fs.s3a.access.key=minioadmin \
        --conf spark.hadoop.fs.s3a.secret.key=minioadmin \
        --conf spark.hadoop.fs.s3a.path.style.access=true

# Trino: Open CLI
trino-cli:
    docker-compose exec trino trino

# Trino: Run a query
trino-query QUERY:
    docker-compose exec trino trino --execute "{{ QUERY }}"

# Superset: Open browser
superset-ui:
    @echo "Opening Superset at http://localhost:8088"
    @echo "Username: admin"
    @echo "Password: admin"
    open http://localhost:8088

# Superset: Open CLI
superset-cli:
    docker-compose exec superset bash

# Superset: Add database connection
superset-add-db NAME URI:
    docker-compose exec superset superset set-database-uri -d "{{ NAME }}" -u "{{ URI }}"

# Superset: Logs
superset-logs:
    docker-compose logs -f superset

# Check all services status
status-all:
    @echo "=== All Services Status ==="
    @docker-compose ps

