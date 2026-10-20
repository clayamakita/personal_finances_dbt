with transactions as (

    select * from {{ ref('stg_google_sheets__cashflow_transactions') }}

),

budget_vs_actual as (

    select * from {{ ref('fct_budget_vs_actual') }}

),

transactions_latest_month as (

    select date_trunc( max( transaction_date ), month ) as latest_month
    from transactions
),

final as (

    select
        budget_month, 
        is_future_month
    from budget_vs_actual
    cross join transactions_latest_month
    where budget_month <= latest_month
        and is_future_month = true

)

select * from final
