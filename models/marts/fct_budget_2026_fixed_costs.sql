with budget as (

    select * from {{ ref('int_budget_2026_fixed_costs_unpivoted') }}

),

budget_aggregated as (

    select 
        budget_category, 
        budget_month, 
        sum(budget_amount) as total_budget_amount
    from budget
    group by 1, 2

), 

added_key as (

    select 
        replace( budget_category, ' ', '_' ) || '-' || cast( budget_month as string ) as budget_fixed_costs_fct_id, 
        budget_category, 
        budget_month, 
        total_budget_amount
    from budget_aggregated
)

select * from added_key