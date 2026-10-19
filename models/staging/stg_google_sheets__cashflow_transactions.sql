with source as (

    select * from {{ source('google_sheets', 'cashflow_transactions') }}

),

cleaned_columns as (

    select
        cast( transaction_id as string ) as transaction_id,
        cast( account as string ) as account_name,
        cast( type as string ) as transaction_type,
        cast( category as string ) as transaction_category,
        cast( `where` as string ) as transaction_location,
        cast( item as string ) as transaction_item,
        cast( amount as numeric ) as transaction_amount,
        cast( qty as float64 ) as quantity,
        cast( unit as string ) as unit,
        {{ parse_sheet_date('date') }} as transaction_date,
        cast( notes as string ) as notes,
        cast( _fivetran_synced as timestamp ) as _loaded_at
    from source
)

select * from cleaned_columns
