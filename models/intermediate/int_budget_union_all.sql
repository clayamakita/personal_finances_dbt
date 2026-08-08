with budget_2026 as (

    select * from {{ ref('int_budget_2026_unpivoted') }}

),

final as (

    select 
        budget_month_id, 
        budget_type, 
        budget_month, 
        budget_amount
    from budget_2026

)

select * from final