with source as (

    select * from {{ source('google_sheets', 'cashflow_type_category') }}

), 

cleaned_columns as (

    select 
        _row as type_category_id, 
        type as cashflow_type, 
        category as cashflow_category, 
        _fivetran_synced as _loaded_at
    from source 

)

select * from cleaned_columns