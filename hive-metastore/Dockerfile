FROM apache/hive:4.0.0

USER root

# Copy MySQL JDBC driver from local directory
COPY mysql-connector-j-8.0.33.jar /opt/hive/lib/mysql-connector-j-8.0.33.jar

# Copy S3A JARs for MinIO access
COPY hadoop-aws-3.3.4.jar /opt/hive/lib/hadoop-aws-3.3.4.jar
COPY aws-java-sdk-bundle-1.12.262.jar /opt/hive/lib/aws-java-sdk-bundle-1.12.262.jar

# Copy Hadoop core-site.xml with S3A configuration
COPY core-site.xml /opt/hadoop/etc/hadoop/core-site.xml

# Set permissions
RUN chown hive:hive /opt/hive/lib/mysql-connector-j-8.0.33.jar && \
    chown hive:hive /opt/hive/lib/hadoop-aws-3.3.4.jar && \
    chown hive:hive /opt/hive/lib/aws-java-sdk-bundle-1.12.262.jar && \
    chown hive:hive /opt/hadoop/etc/hadoop/core-site.xml

USER hive
