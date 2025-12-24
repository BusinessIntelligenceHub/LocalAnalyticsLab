#!/usr/bin/env python3
"""
Initialize Great Expectations expectation suites
Run this after containers are up: just dbt-prod-gx-init
"""

import great_expectations as gx
from great_expectations.core.batch import BatchRequest

def create_dev_suite():
    """Create expectation suite for dev environment validation"""
    context = gx.get_context()
    
    # Create expectation suite
    suite_name = "dev_validation_suite"
    suite = context.create_expectation_suite(
        expectation_suite_name=suite_name,
        overwrite_existing=True
    )
    
    # Add expectations for staging table
    batch_request = BatchRequest(
        datasource_name="trino_dev",
        data_connector_name="default_runtime_data_connector",
        data_asset_name="staging.stg_employees",
        batch_identifiers={"default_identifier_name": "dev_batch"},
        runtime_parameters={"query": "SELECT * FROM hive.dev_analytics_staging.stg_employees"}
    )
    
    validator = context.get_validator(
        batch_request=batch_request,
        expectation_suite_name=suite_name
    )
    
    # Core expectations
    validator.expect_table_row_count_to_be_between(min_value=1, max_value=10000)
    validator.expect_column_values_to_not_be_null(column="employee_id")
    validator.expect_column_values_to_be_unique(column="employee_id")
    validator.expect_column_values_to_not_be_null(column="employee_name")
    validator.expect_column_values_to_not_be_null(column="department")
    validator.expect_column_values_to_be_in_set(
        column="department",
        value_set=["Engineering", "Sales", "Marketing", "HR", "Finance"]
    )
    validator.expect_column_values_to_not_be_null(column="salary")
    validator.expect_column_values_to_be_between(
        column="salary",
        min_value=30000,
        max_value=500000
    )
    validator.expect_column_values_to_be_between(
        column="age",
        min_value=18,
        max_value=100
    )
    
    validator.save_expectation_suite(discard_failed_expectations=False)
    print(f"✓ Created expectation suite: {suite_name}")
    return suite_name


def create_prod_promotion_suite():
    """Create expectation suite for prod promotion validation"""
    context = gx.get_context()
    
    suite_name = "prod_promotion_suite"
    suite = context.create_expectation_suite(
        expectation_suite_name=suite_name,
        overwrite_existing=True
    )
    
    # Stricter expectations for production
    batch_request = BatchRequest(
        datasource_name="trino_dev",
        data_connector_name="default_runtime_data_connector",
        data_asset_name="marts.fct_department_summary",
        batch_identifiers={"default_identifier_name": "promotion_batch"},
        runtime_parameters={"query": "SELECT * FROM hive.dev_analytics_marts.fct_department_summary"}
    )
    
    validator = context.get_validator(
        batch_request=batch_request,
        expectation_suite_name=suite_name
    )
    
    # Production quality gates
    validator.expect_table_row_count_to_be_between(min_value=1, max_value=100)
    validator.expect_column_values_to_not_be_null(column="department")
    validator.expect_column_values_to_be_unique(column="department")
    validator.expect_column_values_to_not_be_null(column="employee_count")
    validator.expect_column_min_to_be_between(column="employee_count", min_value=1)
    validator.expect_column_values_to_not_be_null(column="avg_salary")
    validator.expect_column_min_to_be_between(column="avg_salary", min_value=30000)
    validator.expect_column_values_to_not_be_null(column="total_payroll")
    
    validator.save_expectation_suite(discard_failed_expectations=False)
    print(f"✓ Created expectation suite: {suite_name}")
    return suite_name


def create_prod_monitoring_suite():
    """Create expectation suite for ongoing prod monitoring"""
    context = gx.get_context()
    
    suite_name = "prod_monitoring_suite"
    suite = context.create_expectation_suite(
        expectation_suite_name=suite_name,
        overwrite_existing=True
    )
    
    batch_request = BatchRequest(
        datasource_name="trino_prod",
        data_connector_name="default_runtime_data_connector",
        data_asset_name="marts.dim_employees",
        batch_identifiers={"default_identifier_name": "prod_batch"},
        runtime_parameters={"query": "SELECT * FROM hive.analytics_marts.dim_employees"}
    )
    
    validator = context.get_validator(
        batch_request=batch_request,
        expectation_suite_name=suite_name
    )
    
    # Monitor production data quality
    validator.expect_table_row_count_to_be_between(min_value=1)
    validator.expect_column_values_to_not_be_null(column="employee_id")
    validator.expect_column_values_to_be_unique(column="employee_id")
    validator.expect_column_proportion_of_unique_values_to_be_between(
        column="employee_id",
        min_value=0.99
    )
    
    validator.save_expectation_suite(discard_failed_expectations=False)
    print(f"✓ Created expectation suite: {suite_name}")
    return suite_name


def create_checkpoints():
    """Create checkpoints for automated validation"""
    context = gx.get_context()
    
    # Dev checkpoint
    dev_checkpoint_config = {
        "name": "dev_checkpoint",
        "config_version": 1.0,
        "class_name": "SimpleCheckpoint",
        "run_name_template": "%Y%m%d-%H%M%S-dev-validation",
        "validations": [
            {
                "batch_request": {
                    "datasource_name": "trino_dev",
                    "data_connector_name": "default_runtime_data_connector",
                    "data_asset_name": "staging.stg_employees",
                    "batch_identifiers": {"default_identifier_name": "dev_batch"},
                    "runtime_parameters": {
                        "query": "SELECT * FROM hive.dev_analytics_staging.stg_employees"
                    }
                },
                "expectation_suite_name": "dev_validation_suite"
            }
        ]
    }
    context.add_checkpoint(**dev_checkpoint_config)
    print("✓ Created checkpoint: dev_checkpoint")
    
    # Promotion checkpoint
    promotion_checkpoint_config = {
        "name": "promotion_checkpoint",
        "config_version": 1.0,
        "class_name": "SimpleCheckpoint",
        "run_name_template": "%Y%m%d-%H%M%S-promotion-validation",
        "validations": [
            {
                "batch_request": {
                    "datasource_name": "trino_dev",
                    "data_connector_name": "default_runtime_data_connector",
                    "data_asset_name": "marts.fct_department_summary",
                    "batch_identifiers": {"default_identifier_name": "promotion_batch"},
                    "runtime_parameters": {
                        "query": "SELECT * FROM hive.dev_analytics_marts.fct_department_summary"
                    }
                },
                "expectation_suite_name": "prod_promotion_suite"
            }
        ]
    }
    context.add_checkpoint(**promotion_checkpoint_config)
    print("✓ Created checkpoint: promotion_checkpoint")
    
    # Production monitoring checkpoint
    prod_checkpoint_config = {
        "name": "prod_checkpoint",
        "config_version": 1.0,
        "class_name": "SimpleCheckpoint",
        "run_name_template": "%Y%m%d-%H%M%S-prod-monitoring",
        "validations": [
            {
                "batch_request": {
                    "datasource_name": "trino_prod",
                    "data_connector_name": "default_runtime_data_connector",
                    "data_asset_name": "marts.dim_employees",
                    "batch_identifiers": {"default_identifier_name": "prod_batch"},
                    "runtime_parameters": {
                        "query": "SELECT * FROM hive.analytics_marts.dim_employees"
                    }
                },
                "expectation_suite_name": "prod_monitoring_suite"
            }
        ]
    }
    context.add_checkpoint(**prod_checkpoint_config)
    print("✓ Created checkpoint: prod_checkpoint")


if __name__ == "__main__":
    print("Initializing Great Expectations...")
    print("")
    
    # Create expectation suites
    create_dev_suite()
    create_prod_promotion_suite()
    create_prod_monitoring_suite()
    print("")
    
    # Create checkpoints
    create_checkpoints()
    print("")
    
    print("✓ Great Expectations initialization complete!")
    print("")
    print("Next steps:")
    print("  1. Run dev validation: just dbt-prod-gx-validate-dev")
    print("  2. View Data Docs: just dbt-prod-gx-docs")
