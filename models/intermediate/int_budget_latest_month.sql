with budget as (

    select * from {{ ref('int_budget') }}

),

transactions as (

    select * from {{ ref('stg_google_sheets__cashflow_transactions') }}

),

transactions_latest_month as (

    select 
        date_trunc( max( transaction_date ), month ) as latest_month
    from transactions

),

budget_latest_month as (

    select
        budget_month_id, 
        budget_type, 
        budget_month, 
        budget_amount
    from budget
    where budget_month = ( select latest_month from transactions_latest_month )
)

select * from budget_latest_month