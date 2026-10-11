{# Fails if the column has a value of zero or below. NULLs are allowed. #}
{% test positive_value(model, column_name) %}
    select {{ column_name }}
    from {{ model }}
    where {{ column_name }} <= 0
{% endtest %}
