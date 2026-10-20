{{ config(severity='warn') }}

select
    int.account_name,
    int.current_balance,
    stg.current_balance_sheet
from {{ ref('int_accounts') }} as int
inner join {{ ref('stg_google_sheets__accounts') }} as stg using ( account_name )
where abs( int.current_balance - stg.current_balance_sheet ) > 0.01
