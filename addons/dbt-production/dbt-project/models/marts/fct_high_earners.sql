{{
  config(
    materialized='table',
    tags=['marts', 'fact', 'production']
  )
}}

-- High earners fact table (top 25% by salary)
select
    employee_id,
    employee_name,
    department,
    salary,
    salary_percentile,
    salary_vs_dept_avg,
    current_timestamp as identified_at
from {{ ref('int_employee_metrics') }}
where is_high_earner = true
order by salary desc
