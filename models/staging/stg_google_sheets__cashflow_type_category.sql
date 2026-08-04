select
    _fivetran_synced, 
    _row as type_category_id, 
    type as cashflow_type, 
    category as cashflow_category
from {{ source('google_sheets', 'cashflow_type_category') }}