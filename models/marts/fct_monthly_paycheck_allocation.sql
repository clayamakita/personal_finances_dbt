with transactions as (

    select * from {{ ref('int_cashflow_transactions_agg_month') }}

), 

budget as (

    select * from {{ ref('int_budget_union_all') }}

),

aggregated_budget as (

    select 
        case 
            when budget_type = 'Income' then 'Paycheck' 
            when budget_type like 'Guilt-Free%' then 'Guilt-Free' 
            else budget_type
        end as allocation_type, 
        budget_month, 
        sum( budget_amount ) as budget_amount
    from budget
    where budget_type <> 'Guilt-Free Total'
    and budget_type <> 'Budget'
    group by 1, 2

),

budget_guilt_free as (

    select
        allocation_type, 
        budget_month, 
        budget_amount 
    from aggregated_budget 
    where allocation_type like 'Guilt-Free'

), 

aggregated_transactions as (

    select
        case 
            when transaction_type = 'Income' and transaction_category = 'Paycheck' then 'Paycheck'
            when transaction_type in ( 'Fixed Costs', 'Savings', 'Investments' ) then transaction_type
            when transaction_type like 'Guilt-Free%' then 'Guilt-Free'
            else 'Other'
        end as allocation_type, 
        transaction_month, 
        abs( sum( total_amount ) ) as allocation_amount
    from transactions
    group by 1, 2

), 

adjusted_aggregated_transactions as (

    select 
        transactions.allocation_type, 
        transactions.transaction_month, 
        case 
            when transactions.allocation_type = 'Guilt-Free' then guilt_free.budget_amount 
            else transactions.allocation_amount
        end as allocation_amount
    from aggregated_transactions as transactions
    left join budget_guilt_free as guilt_free
    on guilt_free.allocation_type = transactions.allocation_type
    and guilt_free.budget_month = transactions.transaction_month
    where transactions.allocation_type <> 'Other'
), 

final as (

    select 
        budget.allocation_type, 
        budget.budget_month, 
        budget.budget_amount, 
        coalesce( transactions.allocation_amount, 0 ) as allocation_amount, 
        case 
            when budget.allocation_type in ( 'Paycheck', 'Investments', 'Savings' ) 
                then coalesce( transactions.allocation_amount, 0 ) - budget.budget_amount 
            else budget.budget_amount - coalesce( transactions.allocation_amount, 0 )
        end as allocation_variance
    from aggregated_budget as budget 
    left join adjusted_aggregated_transactions as transactions 
    on transactions.allocation_type = budget.allocation_type 
    and transactions.transaction_month = budget.budget_month

)

select * from final
order by 2, 1
