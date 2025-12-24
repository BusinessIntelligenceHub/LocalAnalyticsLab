-- Test to ensure salary values are within reasonable range
-- This test will fail if any salaries are outside the expected range

select
    employee_id,
    employee_name,
    salary
from {{ ref('stg_employees') }}
where salary < 30000 or salary > 500000
