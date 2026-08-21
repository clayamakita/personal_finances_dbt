with budget as (

    select * from {{ ref('int_budget_fixed_costs') }}

),

final as (

    select 
        budget_fixed_costs_month_id, 
        budget_category, 
        budget_month, 
        budget_amount
    from budget
)

select * from final