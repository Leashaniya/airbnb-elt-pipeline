{# Turn text like '$1,250.00' into the number 1250.00 (NULL if it can't be parsed). #}
{% macro clean_money(column) -%}
    try_to_number(replace(replace({{ column }}, '$', ''), ',', ''), 10, 2)
{%- endmacro %}

{# Turn Airbnb's 't' / 'f' flags into real booleans. #}
{% macro to_bool(column) -%}
    case {{ column }} when 't' then true when 'f' then false end
{%- endmacro %}
