select
    _fivetran_synced, 
    _row as account_id, 
    account as account_name, 
    cast( coalesce( beginning_balance, 0 ) as numeric ) as beginning_balance, 
    cast( coalesce( current_balance, 0 ) as numeric ) as current_balance, 
    account_type, 
    account_category
from {{ source('google_sheets', 'accounts') }}
where account is not null