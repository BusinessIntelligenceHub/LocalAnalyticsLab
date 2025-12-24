-- Test to ensure department summary totals match raw employee count
-- Tests referential integrity between staging and marts

with raw_counts as (
    select
        department,
        count(*) as raw_count
    from {{ ref('stg_employees') }}
    group by department
),

summary_counts as (
    select
        department,
        employee_count as summary_count
    from {{ ref('fct_department_summary') }}
)

select
    r.department,
    r.raw_count,
    s.summary_count,
    abs(r.raw_count - s.summary_count) as difference
from raw_counts r
join summary_counts s
    on r.department = s.department
where r.raw_count != s.summary_count
