select
    _fivetran_synced, 
    _row as investments_transactions_id, 
    date as event_date, 
    account as account_name, 
    type as investment_type, 
    event as investment_event, 
    ticker as investment_ticker, 
    investment_name, 
    cast( qty as numeric) as qty, 
    cast( price as numeric ) as price, 
    cast( total_value as numeric ) as total_value, 
    coalesce( dividends, 0 ) as dividends, 
    cast( net_qty as numeric ) as net_qty
from {{ source('src_google_sheets', 'investments_transactions') }}