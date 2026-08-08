with investments_transactions as (

    select * from {{ ref('stg_google_sheets__investments_transactions') }}

), 

selected_columns as (

    select 
        investment_transaction_id, 
        account_name, 
        investment_type, 
        investment_event, 
        ticker, 
        investment_name, 
        quantity, 
        price, 
        total_value, 
        dividends, 
        net_quantity, 
        event_date
    from investments_transactions

)

select * from selected_columns