with budget_fixed_costs as (

    select * from {{ ref('int_budget_fixed_costs') }}

), 

actual as (

    select * from {{ ref('int_cashflow_transactions_agg_month') }}

), 

actual_agg_category_fixed_costs as (

    select 
        transaction_category, 
        transaction_month, 
        abs( sum( total_amount ) ) as actual_amount
    from actual
    where transaction_type = 'Fixed Costs'
    group by 1, 2
), 

joined_budget_fixed_costs_actual as (

    select
        budget.budget_fixed_costs_month_id, 
        budget.budget_category, 
        budget.budget_month, 
        budget.budget_amount, 
        coalesce( actual.actual_amount, 0 ) as actual_amount, 
        budget.budget_amount - coalesce( actual.actual_amount, 0 ) as variance_amount 
    from budget_fixed_costs as budget
    left join actual_agg_category_fixed_costs as actual 
    on actual.transaction_category = budget.budget_category 
    and actual.transaction_month = budget.budget_month

)

select * from joined_budget_fixed_costs_actual