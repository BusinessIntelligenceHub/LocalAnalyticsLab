{{
  config(
    materialized='table',
    tags=['marts', 'dimension', 'production']
  )
}}

-- Employee dimension table
select
    employee_id,
    employee_name,
    age,
    department,
    salary,
    salary_percentile,
    is_high_earner,
    years_category,
    loaded_at,
    current_timestamp as updated_at
from {{ ref('int_employee_metrics') }}
