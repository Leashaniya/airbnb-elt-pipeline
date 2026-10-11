{# Fails if a rate column falls outside 0 to 1. NULLs are allowed. #}
{% test accepted_range_0_1(model, column_name) %}
    select {{ column_name }}
    from {{ model }}
    where {{ column_name }} < 0 or {{ column_name }} > 1
{% endtest %}
