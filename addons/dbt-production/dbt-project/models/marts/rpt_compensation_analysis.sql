{{
  config(
    materialized='table',
    tags=['marts', 'report', 'production']
  )
}}

-- Compensation analysis report
with dept_summary as (
    select * from {{ ref('fct_department_summary') }}
),

high_earner_count as (
    select
        department,
        count(*) as high_earner_count
    from {{ ref('fct_high_earners') }}
    group by department
)

select
    d.department,
    d.employee_count,
    d.avg_salary,
    d.median_salary,
    d.total_payroll as total_compensation,
    coalesce(h.high_earner_count, 0) as high_earner_count,
    round(cast(coalesce(h.high_earner_count, 0) as double) / d.employee_count * 100, 1) as high_earner_percentage,
    d.snapshot_date
from dept_summary d
left join high_earner_count h
    on d.department = h.department
order by d.total_payroll desc
