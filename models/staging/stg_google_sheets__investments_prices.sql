with source as (

    select * from {{ source('google_sheets', 'investments_price') }}

), 

cleaned_columns as (

    select
        investment_price_id, 
        ticker, 
        investment_name, 
        cast( live_price as numeric ) as latest_price, 
        time_delay, 
        last_trade_time as latest_trade_time, 
        _fivetran_synced as _loaded_at 
    from source

)

select * from cleaned_columns