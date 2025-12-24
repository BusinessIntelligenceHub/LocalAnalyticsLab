{{
  config(
    materialized='view',
    tags=['staging', 'employees']
  )
}}

with source_data as (
    select
        id,
        name,
        age,
        department,
        salary
    from {{ source('raw', 'employees') }}
),

cleaned as (
    select
        id as employee_id,
        trim(name) as employee_name,
        age,
        -- Standardize department names
        case
            when lower(department) like '%eng%' then 'Engineering'
            when lower(department) like '%sale%' then 'Sales'
            when lower(department) like '%market%' then 'Marketing'
            when lower(department) like '%hr%' or lower(department) like '%human%' then 'HR'
            when lower(department) like '%fin%' then 'Finance'
            else department
        end as department,
        salary,
        current_timestamp as loaded_at
    from source_data
    -- Basic data quality filters
    where id is not null
      and name is not null
      and age between 18 and 100
      and salary > 0
)

select * from cleaned
