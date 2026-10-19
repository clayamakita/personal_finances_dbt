with source as (

    select * from {{ source('google_sheets', 'cashflow_type_category') }}

),

cleaned_columns as (

    select
        cast( _row as int64 ) as type_category_id,
        cast( type as string ) as cashflow_type,
        cast( category as string ) as cashflow_category,
        cast( _fivetran_synced as timestamp ) as _loaded_at
    from source

)

select * from cleaned_columns
