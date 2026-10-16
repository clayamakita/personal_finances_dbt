{% macro today() %}
    current_date('{{ var("project_timezone") }}')
{% endmacro %}
