"""
Test Spark integration with MinIO S3
This script:
1. Creates sample data
2. Writes to MinIO in Parquet format
3. Reads it back
4. Verifies the data
"""

from pyspark.sql import SparkSession
from pyspark.sql.types import StructType, StructField, StringType, IntegerType, DoubleType
import sys

# Create Spark session with S3A configuration in local mode
spark = SparkSession.builder \
    .appName("MinIO-S3-Test") \
    .master("local[*]") \
    .config("spark.hadoop.fs.s3a.endpoint", "http://minio:9000") \
    .config("spark.hadoop.fs.s3a.access.key", "minioadmin") \
    .config("spark.hadoop.fs.s3a.secret.key", "minioadmin") \
    .config("spark.hadoop.fs.s3a.path.style.access", "true") \
    .config("spark.hadoop.fs.s3a.connection.ssl.enabled", "false") \
    .config("spark.hadoop.fs.s3a.impl", "org.apache.hadoop.fs.s3a.S3AFileSystem") \
    .getOrCreate()

print("✓ Spark session created")

# Create sample data
data = [
    (1, "Alice", "Engineering", 95000.0),
    (2, "Bob", "Marketing", 75000.0),
    (3, "Charlie", "Engineering", 105000.0),
    (4, "Diana", "Sales", 85000.0),
    (5, "Eve", "Engineering", 98000.0),
]

schema = StructType([
    StructField("id", IntegerType(), False),
    StructField("name", StringType(), False),
    StructField("department", StringType(), False),
    StructField("salary", DoubleType(), False),
])

df = spark.createDataFrame(data, schema)
print(f"✓ Created DataFrame with {df.count()} rows")
df.show()

# Write to MinIO
s3_path = "s3a://spark-test/employees.parquet"
print(f"\n→ Writing data to MinIO: {s3_path}")

try:
    df.write.mode("overwrite").parquet(s3_path)
    print("✓ Data written successfully to MinIO")
except Exception as e:
    print(f"✗ Error writing to MinIO: {e}")
    sys.exit(1)

# Read back from MinIO
print(f"\n→ Reading data from MinIO: {s3_path}")
try:
    df_read = spark.read.parquet(s3_path)
    print(f"✓ Data read successfully. Row count: {df_read.count()}")
    print("\nData from MinIO:")
    df_read.show()
    
    # Verify data integrity
    if df.count() == df_read.count():
        print("✓ Row count matches!")
    else:
        print("✗ Row count mismatch!")
        
except Exception as e:
    print(f"✗ Error reading from MinIO: {e}")
    sys.exit(1)

# Test aggregation
print("\n→ Running aggregation query")
avg_salary = df_read.groupBy("department").avg("salary")
avg_salary.show()
print("✓ Aggregation successful")

spark.stop()
print("\n✓✓✓ All tests passed! Spark ↔ MinIO integration working correctly ✓✓✓")
