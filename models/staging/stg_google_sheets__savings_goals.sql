select
    _fivetran_synced, 
    _row as goal_id, 
    goal_name, 
    priority as goal_priority, 
    initial_target_date, 
    actual_date
from {{ source('src_google_sheets', 'savings_goals') }}