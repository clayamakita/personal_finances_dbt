with transactions as (

    select * from {{ ref('stg_google_sheets__cashflow_transactions') }}

),

paycheck_allocation as (

    select * from {{ ref('fct_monthly_paycheck_allocation') }}

),

transactions_latest_month as (

    select date_trunc( max( transaction_date ), month ) as latest_month
    from transactions
),

final as (

    select
        budget_month, 
        is_future_month
    from paycheck_allocation
    cross join transactions_latest_month
    where budget_month <= latest_month
        and is_future_month = true

)

select * from final
