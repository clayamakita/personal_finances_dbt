{% macro is_inflow_type(column_name) %}
    {{ column_name }} in ('Income', 'Paycheck', 'Investments', 'Savings')
{% endmacro %}

{% macro is_guilt_free(column_name) %}
    {{ column_name }} like 'Guilt-Free%'
{% endmacro %}

{% macro signed_variance(type_column, budget_column, actual_column) %}
    case
        when {{ is_inflow_type(type_column) }} then {{ actual_column }} - {{ budget_column }}
        else {{ budget_column }} - {{ actual_column }}
    end
{% endmacro %}
