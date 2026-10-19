with source as (

    select * from {{ source('google_sheets', 'investments_transactions') }}

),

cleaned_columns as (

    select
        cast( investment_transaction_id as string ) as investment_transaction_id,
        cast( account as string ) as account_name,
        cast( type as string ) as investment_type,
        cast( event as string ) as investment_event,
        cast( ticker as string ) as ticker,
        cast( investment_name as string ) as investment_name,
        cast( qty as numeric ) as quantity,
        cast( price as numeric ) as price,
        cast( total_value as numeric ) as total_value,
        cast( coalesce( dividends, 0 ) as numeric ) as dividends,
        cast( net_qty as numeric ) as net_quantity,
        {{ parse_sheet_date('date') }} as event_date,
        cast( _fivetran_synced as timestamp ) as _loaded_at
    from source
)

select * from cleaned_columns
