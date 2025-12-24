FROM python:3.11-slim

WORKDIR /great_expectations

# Install system dependencies
RUN apt-get update && apt-get install -y \
    gcc \
    g++ \
    && rm -rf /var/lib/apt/lists/*

# Install Great Expectations and required packages
RUN pip install --no-cache-dir \
    great-expectations==0.18.8 \
    sqlalchemy-trino==0.5.0 \
    pandas==2.1.4 \
    numpy==1.26.2

# Expose port for Data Docs
EXPOSE 8080

CMD ["tail", "-f", "/dev/null"]
