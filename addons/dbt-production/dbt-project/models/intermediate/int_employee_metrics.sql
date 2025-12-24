{{
  config(
    materialized='view',
    tags=['intermediate', 'employees', 'metrics']
  )
}}

with employees as (
    select * from {{ ref('stg_employees') }}
),

-- Calculate department-level statistics
dept_stats as (
    select
        department,
        avg(salary) as dept_avg_salary,
        approx_percentile(salary, 0.75) as dept_75th_percentile
    from employees
    group by department
),

-- Add calculations and enrichments
enriched as (
    select
        e.employee_id,
        e.employee_name,
        e.age,
        e.department,
        e.salary,
        
        -- Salary percentile within company
        percent_rank() over (order by e.salary) * 100 as salary_percentile,
        
        -- Department comparison
        d.dept_avg_salary,
        round(((e.salary - d.dept_avg_salary) / d.dept_avg_salary * 100), 2) as salary_vs_dept_avg,
        
        -- Flags
        case
            when e.salary >= d.dept_75th_percentile then true
            else false
        end as is_high_earner,
        
        -- Age-based categories
        case
            when e.age < 25 then 'Early Career'
            when e.age between 25 and 35 then 'Mid Career'
            when e.age between 36 and 50 then 'Senior'
            when e.age > 50 then 'Executive'
        end as years_category,
        
        e.loaded_at
        
    from employees e
    left join dept_stats d
        on e.department = d.department
)

select * from enriched
