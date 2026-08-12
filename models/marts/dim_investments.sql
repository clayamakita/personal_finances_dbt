with transactions as (

    select * from {{ ref('stg_google_sheets__investments_transactions') }}

), 

prices as (

    select * from {{ ref('stg_google_sheets__investments_prices') }}

),

aggregated_transactions as (

    select 
        investment_type, 
        ticker, 
        investment_name, 
        sum( net_quantity ) as total_quantity 
    from transactions
    group by 1, 2, 3 

),

current_position as (

    select 
        transactions.investment_type, 
        transactions.ticker, 
        transactions.investment_name, 
        transactions.total_quantity, 
        prices.latest_price, 
        round( transactions.total_quantity * prices.latest_price, 2 ) as current_value
    from aggregated_transactions as transactions 
    left join prices as prices 
    on prices.ticker = transactions.ticker 
), 

transactions_and_current_position as (

    select 
        ticker, 
        safe_cast( total_value as float64 ) as amount, 
        event_date
    from transactions 

    union all 

    select 
        ticker, 
        safe_cast( current_value as float64 ) as amount, 
        current_date() as event_date
    from current_position

),

calculated_annualized_return as (

    select 
        ticker, 
        round(
            `{{ target.project }}.{{ target.dataset }}.xirr`(
                array_agg( amount order by event_date ),
                array_agg( cast( event_date as string) order by event_date )
                ), 4 )
        as annualized_return_rate 
    from transactions_and_current_position
    group by ticker
),

added_annualized_return_to_current_position as (

    select
        position.ticker, 
        position.investment_name, 
        position.total_quantity, 
        position.latest_price, 
        position.current_value, 
        rate.annualized_return_rate
    from current_position as position 
    left join calculated_annualized_return as rate 
    on rate.ticker = position.ticker
)

select * from added_annualized_return_to_current_position
