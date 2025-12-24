{{
  config(
    materialized='table',
    tags=['marts', 'fact', 'production']
  )
}}

-- Department summary fact table
select
    department,
    employee_count,
    avg_salary,
    median_salary,
    min_salary,
    max_salary,
    total_payroll,
    avg_age,
    current_timestamp as snapshot_date
from {{ ref('int_department_stats') }}
