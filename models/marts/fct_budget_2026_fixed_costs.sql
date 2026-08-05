with budget as (

    select * from {{ ref('int_budget_2026_fixed_costs_unpivoted') }}

),

budget_aggregated as (

    select 
        {{ dbt_utils.generate_surrogate_key(['budget_category', 'budget_month']) }} as fct_budget_fixed_costs_id, 
        budget_category, 
        budget_month, 
        sum(budget_amount) as total_budget_amount
    from budget
    group by 1, 2, 3

)

select * from budget_aggregated