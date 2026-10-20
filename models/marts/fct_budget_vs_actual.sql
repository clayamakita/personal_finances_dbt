with budget as (

    select * from {{ ref('int_budget') }}

),

actual as (

    select * from {{ ref('int_cashflow_transactions_agg_month') }}

),

actual_latest_month as (

    select date_trunc( max( transaction_month ), month ) as latest_month
    from actual

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
        budget.budget_month > ( select latest_month from actual_latest_month ) as is_future_month,
        budget.budget_amount,
        coalesce( actual.actual_amount, 0 ) as actual_amount,
        {{ signed_variance('budget_type', 'budget.budget_amount', 'coalesce(actual.actual_amount, 0)') }} as variance_amount
    from budget
    left join actual_agg_type as actual
        on budget.budget_type = actual.transaction_type
        and budget.budget_month = actual.transaction_month

)

select * from joined_budget_actual
