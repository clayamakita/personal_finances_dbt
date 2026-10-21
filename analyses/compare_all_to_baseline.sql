{# Compares EVERY model in your dev build with the baseline built from main.
   Click Preview. With show_only_differences = true, an empty result means every model matches. #}
{% set show_only_differences = true %}  {# false shows the row counts for every model #}
{% set layered = false %}               {# set to true after PR-26 (each layer in its own dataset) #}
{% set baseline_schema = 'analytics' %} {# used while layered = false #}
{% set skip_models = [] %}              {# e.g. models that don't exist in the baseline yet #}
{% set excluded_columns = {
    'dim_investments': ['latest_price', 'current_value', 'annualized_return_rate'],
    'retirement_projection': ['current_value', 'future_value']
} %}                                    {# price- or date-driven columns, per model #}

{% set queries = [] %}
{% if execute %}
    {% for node in graph.nodes.values() | selectattr('resource_type', 'equalto', 'model') | sort(attribute='name') %}
        {% if node.package_name == project_name and node.name not in skip_models %}
            {% set schema = node.fqn[1] if layered else baseline_schema %}
            {% set model_summary %}
                select
                    '{{ node.name }}' as model_name,
                    in_a,
                    in_b,
                    `count`,
                    percent_of_total
                from (
                    {{ audit_helper.compare_relations(
                        a_relation = api.Relation.create(
                            database = node.database,
                            schema = node.schema,
                            identifier = node.alias
                        ),
                        b_relation = api.Relation.create(
                            database = target.database,
                            schema = schema,
                            identifier = node.alias
                        ),
                        exclude_columns = excluded_columns.get(node.name, [])
                    ) }}
                )
            {% endset %}
            {% do queries.append(model_summary) %}
        {% endif %}
    {% endfor %}
{% endif %}

select *
from (
    {{ queries | join('\n    union all\n') }}
)
{% if show_only_differences %}
where not (in_a and in_b)
{% endif %}
order by model_name