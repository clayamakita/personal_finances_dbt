with transactions as (
    
    select * from {{ ref('stg_google_sheets__cashflow_transactions') }}

),

selected_columns as (

    select 
        transaction_id, 
        account_name, 
        transaction_type, 
        transaction_category, 
        transaction_location, 
        transaction_item, 
        transaction_amount, 
        qty, 
        unit, 
        transaction_date, 
        notes
    from transactions
)

select * from selected_columns