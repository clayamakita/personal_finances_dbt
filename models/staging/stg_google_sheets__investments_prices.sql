select
    _fivetran_synced, 
    _row as investments_price_id, 
    ticker as investment_ticker, 
    investment_name, 
    live_price as latest_price, 
    last_trade_time, 
    time_delay
from {{ source('google_sheets', 'investments_price') }}