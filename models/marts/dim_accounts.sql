select 
  account_name,
  account_type, 
  account_category, 
  beginning_balance
from {{ ref('stg_google_sheets__accounts') }}
