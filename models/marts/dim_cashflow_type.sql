with type_category as (

    select * from {{ ref('stg_google_sheets__cashflow_type_category') }}

),

selected_columns as (

    select 
        distinct {{ dbt_utils.generate_surrogate_key(['cashflow_type']) }} as cashflow_type_id, 
        cashflow_type
    from type_category

)

select * from selected_columns