-- Macro to create schemas if they don't exist
{% macro create_schema_if_not_exists() %}
  {% if target.name == 'dev' %}
    {% set schemas = ['dev_analytics', 'dev_analytics_staging', 'dev_analytics_intermediate', 'dev_analytics_marts'] %}
  {% elif target.name == 'prod' %}
    {% set schemas = ['analytics', 'analytics_staging', 'analytics_intermediate', 'analytics_marts'] %}
  {% endif %}
  
  {% for schema in schemas %}
    create schema if not exists hive.{{ schema }};
  {% endfor %}
{% endmacro %}

-- Macro to test if a value is positive
{% test positive_values(model, column_name) %}
select *
from {{ model }}
where {{ column_name }} <= 0
{% endtest %}

-- Macro to get row count
{% macro get_row_count(model_name) %}
  {% set query %}
    select count(*) as row_count
    from {{ ref(model_name) }}
  {% endset %}
  
  {% set results = run_query(query) %}
  {% if execute %}
    {% set row_count = results.columns[0].values()[0] %}
    {{ return(row_count) }}
  {% endif %}
{% endmacro %}
