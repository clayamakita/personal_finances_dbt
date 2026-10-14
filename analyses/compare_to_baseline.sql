{# Compares one model in your dev dataset with the same model built by the baseline job.
   Edit the four settings below, then click Preview. #}
{% set model_name = 'dim_accounts' %}
{% set primary_key = 'account_id' %}
{% set baseline_schema = 'analytics' %}
{% set excluded_columns = [] %}         {# e.g. ['latest_price', 'current_value'] for price- or date-driven columns #}

{{ audit_helper.compare_relations(
    a_relation = ref(model_name),
    b_relation = api.Relation.create(
        database = target.database,
        schema = baseline_schema,
        identifier = model_name
    ),
    exclude_columns = excluded_columns,
    primary_key = primary_key
) }}
