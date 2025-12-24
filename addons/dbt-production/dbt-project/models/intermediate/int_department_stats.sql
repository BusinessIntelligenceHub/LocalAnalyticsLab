{{
  config(
    materialized='view',
    tags=['intermediate', 'department', 'aggregation']
  )
}}

with employees as (
    select * from {{ ref('stg_employees') }}
),

department_aggregations as (
    select
        department,
        count(*) as employee_count,
        round(avg(salary), 2) as avg_salary,
        approx_percentile(salary, 0.5) as median_salary,
        min(salary) as min_salary,
        max(salary) as max_salary,
        sum(salary) as total_payroll,
        round(avg(age), 1) as avg_age
    from employees
    group by department
)

select * from department_aggregations
