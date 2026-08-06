with source as (

    select * from {{ source('google_sheets', 'investments_transactions') }}

),

cleaned_columns as (

    select
        investment_transaction_id, 
        account as account_name, 
        type as investment_type, 
        event as investment_event, 
        ticker as investment_ticker, 
        investment_name, 
        cast( qty as numeric) as qty, 
        cast( price as numeric ) as price, 
        cast( total_value as numeric ) as total_value, 
        cast( coalesce( dividends, 0 ) as numeric ) as dividends, 
        cast( net_qty as numeric ) as net_qty, 
        safe.parse_date( '%d/%b/%Y', date ) as event_date,  
        _fivetran_synced as _loaded_at
    from source
)

select * from cleaned_columns