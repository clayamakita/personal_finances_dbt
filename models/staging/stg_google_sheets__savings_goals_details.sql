select
    _fivetran_synced, 
    _row as goals_details_id, 
    account as account_name, 
    goal_name, 
    item as goal_item, 
    cast( amount as numeric) as goal_amount
from {{ source('google_sheets', 'savings_goals_details') }}