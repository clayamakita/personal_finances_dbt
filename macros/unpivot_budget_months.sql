{% macro unpivot_budget_months(relation, year, id_columns) %}
    {%- set months = ['january','february','march','april','may','june',
                      'july','august','september','october','november','december'] -%}
    select
        {{ id_columns | join(', ') }},
        parse_date('%B %Y', replace(month_column, '_', ' ')) as budget_month,
        cast(amount as numeric) as budget_amount
    from {{ relation }}
    unpivot(
        amount for month_column in (
            {%- for m in months %}
            {{ m }}_{{ year }}{{ "," if not loop.last }}
            {%- endfor %}
        )
    )
{% endmacro %}
