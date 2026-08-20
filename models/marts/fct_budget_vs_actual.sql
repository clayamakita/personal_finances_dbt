with budget as (

    select * from {{ ref('int_budget') }}

), 

actual as (

    select * from {{ ref('int_cashflow_transactions_agg_month') }}

),

actual_agg_type as (

    select 
        transaction_type, 
        transaction_month, 
        abs( sum( total_amount ) ) as actual_amount 
    from actual
    group by 1, 2 

),

joined_budget_actual as (

    select
        budget.budget_month_id, 
        budget.budget_type, 
        budget.budget_month, 
        budget.budget_amount, 
        coalesce( actual.actual_amount, 0 ) as actual_amount, 
        case
            when budget_type in ( 'Income', 'Investments', 'Savings' ) 
                then coalesce( actual.actual_amount, 0 ) - budget.budget_amount
            else budget.budget_amount - coalesce( actual.actual_amount, 0 ) 
        end as variance_amount 
    from budget 
    left join actual_agg_type as actual
    on actual.transaction_type = budget.budget_type 
    and actual.transaction_month = budget.budget_month
    where budget.budget_type <> 'Budget' 

)

select * from joined_budget_actual