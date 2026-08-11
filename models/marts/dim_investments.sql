with investments_transactions as (

    select * from {{ ref('stg_google_sheets__investments_transactions') }}

), 

investments_prices as (

    select * from {{ ref('stg_google_sheets__investments_prices') }}

),

aggregated_transactions as (

    select 
        investment_type, 
        ticker, 
        investment_name, 
        sum( net_quantity ) as total_quantity 
    from investments_transactions
    group by 1, 2, 3 

),

joined_investments_prices as (

    select 
        transactions.investment_type, 
        transactions.ticker, 
        transactions.investment_name, 
        transactions.total_quantity, 
        prices.latest_price, 
        round( transactions.total_quantity * prices.latest_price, 2 ) as total_value
    from aggregated_transactions as transactions 
    left join investments_prices as prices 
    on prices.ticker = transactions.ticker 
)

select * from joined_investments_prices