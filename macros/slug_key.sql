{% macro slug_key(text_columns, date_column=none) %}
    {%- set pieces = [] -%}
    {%- for col in text_columns -%}
        {%- do pieces.append("lower(replace(replace(" ~ col ~ ", '-', ''), ' ', ''))") -%}
    {%- endfor -%}
    {%- if date_column -%}
        {%- do pieces.append("cast(" ~ date_column ~ " as string)") -%}
    {%- endif -%}
    {{ pieces | join(" || '_' || ") }}
{% endmacro %}
