with source as (

    select * from {{ source('google_sheets', 'investments_price') }}

),

cleaned_columns as (

    select
        cast( investment_price_id as string ) as investment_price_id,
        cast( ticker as string ) as ticker,
        cast( investment_name as string ) as investment_name,
        cast( live_price as numeric ) as latest_price,
        cast( time_delay as int64 ) as time_delay,
        cast( last_trade_time as datetime ) as latest_trade_time,
        cast( _fivetran_synced as timestamp ) as _loaded_at
    from source

)

select * from cleaned_columns
