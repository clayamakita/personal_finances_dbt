with budget as (
    
    select * from {{ ref('int_budget_union_all') }}

), 

actual as (

    select * from {{ ref('int_cashflow_transactions_agg_month') }}

),

actual_agg_month_guilt_free as (

    select 
        transaction_type, 
        transaction_month, 
        abs( sum( total_amount ) ) as actual_amount 
    from actual 
    group by 1, 2 

), 

joined_budget_actual_guilt_free as (

    select 
        budget.budget_month_id, 
        budget.budget_type,
        budget.budget_month, 
        budget.budget_amount, 
        coalesce( actual.actual_amount, 0 ) as actual_amount 
    from budget
    left join actual_agg_month_guilt_free as actual 
    on actual.transaction_type = budget.budget_type 
    and actual.transaction_month = budget.budget_month
    where budget.budget_type like 'Guilt-Free%'

), 

added_running_amount as (

    select 
        budget_month_id, 
        budget_type, 
        budget_month, 
        budget_amount, 
        actual_amount, 
        sum( budget_amount ) over( partition by budget_type order by budget_month ) as running_budget_amount, 
        sum( actual_amount ) over( partition by budget_type order by budget_month ) as running_actual_amount
    from joined_budget_actual_guilt_free
), 

added_variance_amount as (

    select 
        budget_month_id, 
        budget_type, 
        budget_month, 
        budget_amount, 
        actual_amount, 
        running_budget_amount, 
        running_actual_amount, 
        running_budget_amount - running_actual_amount as running_variance_amount
    from added_running_amount
)

select * from added_variance_amount