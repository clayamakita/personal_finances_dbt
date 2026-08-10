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

),

added_key as (

    select 
        lower( replace( replace( transaction_type, '-' , '' ), ' ', '' ) ) || '_' || 
            lower( replace( transaction_category, ' ', '' ) ) || '_' || 
            cast( transaction_month as string ) 
        as transaction_month_id, 
        transaction_type, 
        transaction_category, 
        transaction_month, 
        total_amount 
    from aggregated_month
)

select * from added_key