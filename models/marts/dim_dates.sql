with budget as (

    select * from {{ ref('int_budget_2026_unpivoted') }}

),

cashflow_transactions as (

    select * from {{ ref('stg_google_sheets__cashflow_transactions') }}
), 

investments_transactions as (

    select * from {{ ref('stg_google_sheets__investments_transactions') }}

), 

min_dates as (

    select min(budget_month) as min_date from budget 

    union all  

    select min(transaction_date) as min_date from cashflow_transactions

    union all 

    select min(event_date) as min_date from investments_transactions

), 

start_date as (

    select date_trunc( min( min_date ), year ) as min_all_dates
    from min_dates

), 

end_date as (

    select last_day( max( transaction_date ), year ) as max_transaction_date
    from cashflow_transactions
),

final as (

    select
        cast( format_date('%Y%m%d', single_date) as INT64) as date_id,
        single_date as calendar_date,
        extract(year from single_date) AS calendar_year,
        extract(quarter from single_date) AS calendar_quarter,
        extract(month from single_date) AS month_number,
        format_date('%B', single_date) AS month_name, -- full name (e.g., 'January')
        extract(day from single_date) AS day_number,
        format_date('%A', single_date) AS day_of_week_name -- full name (e.g., 'Monday')
    from
    unnest(
        generate_date_array(
            (select min_all_dates from start_date), 
            (select max_transaction_date from end_date), 
            interval 1 day
        )
    ) AS single_date
)

select * from final