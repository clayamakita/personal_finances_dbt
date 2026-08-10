with budget_2026_fixed_costs as (

    select * from {{ ref('int_budget_2026_fixed_costs_agg_category') }}

), 

final as (
    
    select
        budget_fixed_costs_month_id, 
        budget_category, 
        budget_month, 
        budget_amount
    from budget_2026_fixed_costs

)

select * from final