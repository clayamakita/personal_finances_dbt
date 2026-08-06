with category as (

    select * from {{ ref('stg_google_sheets__cashflow_type_category') }}

), 

selected_columns as (

    select 
        type_category_id as cashflow_category_id, 
        cashflow_category, 
        cashflow_type
    from category
)

select * from selected_columns