with accounts as (

    select * from {{ ref('stg_google_sheets__accounts') }}

), 
transactions as (

    select * from {{ ref('stg_google_sheets__cashflow_transactions') }}

),
transactions_total as (

    select
        account_name,
        sum(transaction_amount) as total_amount
    from transactions
    group by account_name

),
final as (

    select 
        accounts.account_name,
        accounts.account_type, 
        accounts.account_category, 
        accounts.beginning_balance, 
        accounts.beginning_balance + coalesce( transactions_total.total_amount, 0 ) as current_balance
    from accounts
    left join transactions_total 
    on transactions_total.account_name = accounts.account_name

)
select * from final
