-- Initialize schemas for dev and prod environments
-- Run this after starting the addon: just dbt-prod-init

-- DEV ENVIRONMENT SCHEMAS
CREATE SCHEMA IF NOT EXISTS hive.dev_analytics;
CREATE SCHEMA IF NOT EXISTS hive.dev_analytics_staging;
CREATE SCHEMA IF NOT EXISTS hive.dev_analytics_intermediate;
CREATE SCHEMA IF NOT EXISTS hive.dev_analytics_marts;
CREATE SCHEMA IF NOT EXISTS hive.dev_analytics_seeds;
CREATE SCHEMA IF NOT EXISTS hive.dev_analytics_test_failures;

-- PROD ENVIRONMENT SCHEMAS
CREATE SCHEMA IF NOT EXISTS hive.analytics;
CREATE SCHEMA IF NOT EXISTS hive.analytics_staging;
CREATE SCHEMA IF NOT EXISTS hive.analytics_intermediate;
CREATE SCHEMA IF NOT EXISTS hive.analytics_marts;
CREATE SCHEMA IF NOT EXISTS hive.analytics_seeds;
CREATE SCHEMA IF NOT EXISTS hive.analytics_test_failures;

-- Verify schemas were created
SHOW SCHEMAS IN hive LIKE '%analytics%';
