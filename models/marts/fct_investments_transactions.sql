with investments_transactions as (

    select * from {{ ref('stg_google_sheets__investments_transactions') }}

), 

selected_columns as (

    select 
        investments_transactions_id, 
        account_name, 
        investment_type, 
        investment_event, 
        investment_ticker, 
        investment_name, 
        qty, 
        price, 
        total_value, 
        dividends, 
        net_qty, 
        event_date
    from investments_transactions
)

select * from selected_columns