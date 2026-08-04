select
    _fivetran_synced, 
    _row as transaction_id, 
    account as account_name, 
    date as transaction_date, 
    'where' as transaction_location, 
    item as transaction_item, 
    type as transaction_type, 
    category as transaction_category, 
    cast( amount as numeric ) as transaction_amount, 
    qty, 
    unit, 
    notes
from {{ source('src_google_sheets', 'cashflow_transactions') }}