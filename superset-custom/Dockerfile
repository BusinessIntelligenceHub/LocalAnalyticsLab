FROM apache/superset:latest

# Install Trino driver into Superset's venv
# Use system pip but target the venv site-packages directory
USER root
COPY requirements-local.txt /tmp/requirements-local.txt
RUN pip install --target=/app/.venv/lib/python3.10/site-packages --no-cache-dir -r /tmp/requirements-local.txt
USER superset
