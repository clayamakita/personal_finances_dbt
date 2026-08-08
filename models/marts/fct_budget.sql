with budget as (

    select * from {{ ref('int_budget_2026_unpivoted') }}

), 

final as (

    select
        budget_month_id, 
        budget_type, 
        budget_month, 
        budget_amount
    from budget

)

select * from final