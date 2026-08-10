with transactions as (

    select * from {{ ref('stg_google_sheets__cashflow_transactions') }}

),

aggregated_month as (

    select
        transaction_type, 
        transaction_category,
        date_trunc( transaction_date, month ) as transaction_month,  
        sum( transaction_amount ) as total_amount
    from transactions
    group by 1, 2, 3

)

select * from aggregated_month