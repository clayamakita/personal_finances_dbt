with budget as (

    select * from {{ ref('int_budget_2026_fixed_costs_unpivoted') }}

),

aggregated_category as (

    select 
        budget_category, 
        budget_month, 
        sum( budget_amount ) as budget_amount
    from budget
    group by 1, 2
    
), 

added_key as (

    select 
        lower( replace( budget_category, ' ', '' ) ) || '_' || cast( budget_month as string ) AS budget_fixed_costs_month_id, 
        budget_category, 
        budget_month, 
        budget_amount
    from aggregated_category
)

select * from added_key