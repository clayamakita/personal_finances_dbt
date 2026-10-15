{# Compares row counts and column sums of EVERY model: your dev build vs the baseline.
   Click Preview. With show_only_differences = true, an empty result means everything matches. #}
{% set show_only_differences = true %}
{% set layered = false %}               {# set to true after PR-26 #}
{% set baseline_schema = 'analytics' %} {# used while layered = false #}
{% set skip_models = [] %}
{% set excluded_columns = {
    'dim_investments': ['latest_price', 'current_value']
} %}
{% set numeric_types = ['INT64', 'INTEGER', 'FLOAT64', 'FLOAT', 'NUMERIC', 'DECIMAL', 'BIGNUMERIC', 'BIGDECIMAL'] %}

{% set queries = [] %}
{% if execute %}
    {% for node in graph.nodes.values() | selectattr('resource_type', 'equalto', 'model') | sort(attribute='name') %}
        {% if node.package_name == project_name and node.name not in skip_models %}
            {% set schema = node.fqn[1] if layered else baseline_schema %}
            {% set dev = api.Relation.create(database=node.database, schema=node.schema, identifier=node.alias) %}
            {% set base = api.Relation.create(database=node.database, schema=schema, identifier=node.alias) %}
            {% set skipped = excluded_columns.get(node.name, []) %}

            {% set row_counts %}
                select
                    '{{ node.name }}' as model_name,
                    '(row count)' as column_name,
                    cast((select count(*) from {{ dev }}) as float64) as dev_value,
                    cast((select count(*) from {{ base }}) as float64) as baseline_value
            {% endset %}
            {% do queries.append(row_counts) %}

            {% for col in adapter.get_columns_in_relation(dev) %}
                {% if col.data_type | upper in numeric_types and col.name not in skipped %}
                    {% set column_sum %}
                        select
                            '{{ node.name }}' as model_name,
                            '{{ col.name }}' as column_name,
                            round(cast((select sum({{ col.name }}) from {{ dev }}) as float64), 2) as dev_value,
                            round(cast((select sum({{ col.name }}) from {{ base }}) as float64), 2) as baseline_value
                    {% endset %}
                    {% do queries.append(column_sum) %}
                {% endif %}
            {% endfor %}
        {% endif %}
    {% endfor %}
{% endif %}

select *
from (
    {{ queries | join('\n    union all\n') }}
)
{% if show_only_differences %}
where dev_value is distinct from baseline_value
{% endif %}
order by model_name, column_name
