"""
DBT Production Pipeline - Full CI/CD Workflow
Demonstrates production-grade data transformation pipeline with:
- Dev environment testing
- Great Expectations validation
- Automated promotion to production
- Post-deployment validation
"""

from airflow import DAG
from airflow.operators.bash import BashOperator
from airflow.operators.python import PythonOperator, BranchPythonOperator
from airflow.operators.empty import EmptyOperator
from airflow.utils.trigger_rule import TriggerRule
from datetime import datetime, timedelta
import json

default_args = {
    'owner': 'data-team',
    'depends_on_past': False,
    'start_date': datetime(2025, 1, 1),
    'email_on_failure': False,
    'email_on_retry': False,
    'retries': 1,
    'retry_delay': timedelta(minutes=2)
}

with DAG(
    'dbt_production_cicd_pipeline',
    default_args=default_args,
    description='Full CI/CD pipeline for DBT transformations',
    schedule_interval=None,  # Triggered manually or by upstream processes
    catchup=False,
    tags=['dbt', 'production', 'cicd', 'data-quality']
) as dag:

    # =========================================================================
    # PHASE 1: DEV ENVIRONMENT - BUILD AND TEST
    # =========================================================================
    
    start = EmptyOperator(
        task_id='start_pipeline',
        dag=dag
    )
    
    # Install DBT dependencies
    dbt_deps = BashOperator(
        task_id='dbt_install_dependencies',
        bash_command='docker exec dbt-dev dbt deps',
        dag=dag
    )
    
    # Run DBT models in dev environment
    dbt_dev_run = BashOperator(
        task_id='dbt_dev_run_models',
        bash_command='docker exec dbt-dev dbt run --target dev --full-refresh',
        dag=dag
    )
    
    # Run DBT tests in dev
    dbt_dev_test = BashOperator(
        task_id='dbt_dev_test_models',
        bash_command='docker exec dbt-dev dbt test --target dev',
        dag=dag
    )
    
    # Generate DBT documentation
    dbt_dev_docs = BashOperator(
        task_id='dbt_dev_generate_docs',
        bash_command='docker exec dbt-dev dbt docs generate --target dev',
        dag=dag
    )
    
    # =========================================================================
    # PHASE 2: GREAT EXPECTATIONS VALIDATION (DEV)
    # =========================================================================
    
    gx_dev_validate = BashOperator(
        task_id='great_expectations_dev_validation',
        bash_command='''
docker exec great-expectations python << 'EOF'
import great_expectations as gx
import sys

context = gx.get_context()
checkpoint = context.get_checkpoint("dev_checkpoint")
result = checkpoint.run()

if not result.success:
    print("❌ Dev validation failed!")
    print(result)
    sys.exit(1)
else:
    print("✓ Dev validation passed!")
    sys.exit(0)
EOF
        ''',
        dag=dag
    )
    
    # =========================================================================
    # PHASE 3: PROMOTION DECISION GATE
    # =========================================================================
    
    def check_promotion_readiness(**context):
        """
        Check if code is ready for production promotion
        In real scenarios, this could check:
        - All tests passed
        - Code review approved
        - Manual approval received
        - No blocking issues in Jira
        - Data quality thresholds met
        """
        # For demo, auto-approve if we got this far
        ti = context['ti']
        
        # Could pull test results from XCom
        # test_result = ti.xcom_pull(task_ids='dbt_dev_test_models')
        
        # Simulate promotion criteria check
        promotion_ready = True  # In reality, check actual conditions
        
        if promotion_ready:
            print("✓ Promotion criteria met - proceeding to production")
            return 'run_promotion_validation'
        else:
            print("❌ Promotion criteria not met - skipping production deployment")
            return 'skip_production'
    
    promotion_gate = BranchPythonOperator(
        task_id='promotion_decision_gate',
        python_callable=check_promotion_readiness,
        provide_context=True,
        dag=dag
    )
    
    # =========================================================================
    # PHASE 4: PRE-PRODUCTION VALIDATION
    # =========================================================================
    
    gx_promotion_validate = BashOperator(
        task_id='run_promotion_validation',
        bash_command='''
docker exec great-expectations python << 'EOF'
import great_expectations as gx
import sys

context = gx.get_context()
checkpoint = context.get_checkpoint("promotion_checkpoint")
result = checkpoint.run()

if not result.success:
    print("❌ Promotion validation failed!")
    print(result)
    sys.exit(1)
else:
    print("✓ Promotion validation passed!")
    sys.exit(0)
EOF
        ''',
        dag=dag
    )
    
    # =========================================================================
    # PHASE 5: PRODUCTION DEPLOYMENT
    # =========================================================================
    
    # Run DBT models in production
    dbt_prod_run = BashOperator(
        task_id='dbt_prod_deploy_models',
        bash_command='docker exec dbt-prod dbt run --target prod',
        dag=dag
    )
    
    # Run DBT tests in production
    dbt_prod_test = BashOperator(
        task_id='dbt_prod_test_models',
        bash_command='docker exec dbt-prod dbt test --target prod --store-failures',
        dag=dag
    )
    
    # =========================================================================
    # PHASE 6: POST-DEPLOYMENT VALIDATION
    # =========================================================================
    
    gx_prod_monitor = BashOperator(
        task_id='great_expectations_prod_monitoring',
        bash_command='''
docker exec great-expectations python << 'EOF'
import great_expectations as gx
import sys

context = gx.get_context()
checkpoint = context.get_checkpoint("prod_checkpoint")
result = checkpoint.run()

if not result.success:
    print("⚠️  Production monitoring detected issues!")
    print(result)
    # Don't fail the pipeline, just warn
    sys.exit(0)
else:
    print("✓ Production data quality validated!")
    sys.exit(0)
EOF
        ''',
        trigger_rule=TriggerRule.ALL_SUCCESS,
        dag=dag
    )
    
    # =========================================================================
    # PHASE 7: DOCUMENTATION AND REPORTING
    # =========================================================================
    
    # Generate production documentation
    dbt_prod_docs = BashOperator(
        task_id='dbt_prod_generate_docs',
        bash_command='docker exec dbt-prod dbt docs generate --target prod',
        dag=dag
    )
    
    # Generate Great Expectations data docs
    gx_build_docs = BashOperator(
        task_id='great_expectations_build_data_docs',
        bash_command='docker exec great-expectations python -c "import great_expectations as gx; gx.get_context().build_data_docs()"',
        dag=dag
    )
    
    def log_deployment_summary(**context):
        """Log summary of deployment"""
        ti = context['ti']
        execution_date = context['execution_date']
        
        summary = {
            'pipeline': 'dbt_production_cicd_pipeline',
            'execution_date': str(execution_date),
            'environment': 'production',
            'status': 'success',
            'models_deployed': 'All models',
            'data_docs': 'http://localhost:8083'
        }
        
        print("=" * 80)
        print("DEPLOYMENT SUMMARY")
        print("=" * 80)
        for key, value in summary.items():
            print(f"{key:20}: {value}")
        print("=" * 80)
        print("\nView Great Expectations Data Docs:")
        print("  just dbt-prod-gx-docs")
        print("\nView DBT Documentation:")
        print("  just dbt-prod-docs-serve")
        
        return summary
    
    deployment_summary = PythonOperator(
        task_id='log_deployment_summary',
        python_callable=log_deployment_summary,
        provide_context=True,
        trigger_rule=TriggerRule.ALL_SUCCESS,
        dag=dag
    )
    
    # Skip path
    skip_production = EmptyOperator(
        task_id='skip_production',
        dag=dag
    )
    
    # End
    end = EmptyOperator(
        task_id='pipeline_complete',
        trigger_rule=TriggerRule.NONE_FAILED_MIN_ONE_SUCCESS,
        dag=dag
    )
    
    # =========================================================================
    # DEFINE WORKFLOW
    # =========================================================================
    
    # Phase 1: Dev environment
    start >> dbt_deps >> dbt_dev_run >> dbt_dev_test >> dbt_dev_docs
    
    # Phase 2: Dev validation
    dbt_dev_docs >> gx_dev_validate
    
    # Phase 3: Decision gate
    gx_dev_validate >> promotion_gate
    
    # Phase 4-7: Production path
    promotion_gate >> gx_promotion_validate >> dbt_prod_run >> dbt_prod_test
    dbt_prod_test >> gx_prod_monitor >> [dbt_prod_docs, gx_build_docs]
    [dbt_prod_docs, gx_build_docs] >> deployment_summary >> end
    
    # Skip path
    promotion_gate >> skip_production >> end
