with transactions as (

    select * from {{ ref('int_cashflow_transactions_agg_month') }}

),

budget as (

    select * from {{ ref('int_budget') }}

),

aggregated_budget as (

    select
        case
            when budget_type = 'Income' then 'Paycheck'
            when {{ is_guilt_free('budget_type') }} then 'Guilt-Free'
            else budget_type
        end as allocation_type,
        budget_month,
        sum( budget_amount ) as budget_amount
    from budget
    group by 1, 2

),

transactions_latest_month as (

    select date_trunc( max( transaction_month ), month ) as latest_month
    from transactions

),

aggregated_transactions as (

    select
        case
            when transaction_type = 'Income' and transaction_category = 'Paycheck' then 'Paycheck'
            when transaction_type in ( 'Fixed Costs', 'Savings', 'Investments' ) then transaction_type
            when {{ is_guilt_free('transaction_type') }} then 'Guilt-Free'
            else 'Other'
        end as allocation_type,
        transaction_month,
        abs( sum( total_amount ) ) as allocation_amount
    from transactions
    group by 1, 2

),

adjusted_guilt_free as (

    select
        budget.allocation_type,
        budget.budget_month,
        budget.budget_month > ( select latest_month from transactions_latest_month ) as is_future_month,
        budget.budget_amount,
        case
            when budget.allocation_type = 'Guilt-Free' then budget.budget_amount
            else coalesce( transactions.allocation_amount, 0 )
        end as allocation_amount
    from aggregated_budget as budget
    left join aggregated_transactions as transactions
        on budget.allocation_type = transactions.allocation_type
        and budget.budget_month = transactions.transaction_month

),

final as (

    select
        *,
        {{ signed_variance('allocation_type', 'budget_amount', 'allocation_amount') }} as allocation_variance
    from adjusted_guilt_free

)

select * from final
