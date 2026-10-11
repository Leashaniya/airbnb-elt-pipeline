{# Use the folder's schema name as-is (STAGING, INTERMEDIATE, MARTS)
   instead of dbt's default of prefixing it with the target schema. #}
{% macro generate_schema_name(custom_schema_name, node) -%}
    {{ custom_schema_name | trim if custom_schema_name else target.schema }}
{%- endmacro %}
