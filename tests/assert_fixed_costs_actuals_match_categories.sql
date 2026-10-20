with by_category as (

    select
        budget_month,
        sum( actual_amount ) as category_total
    from {{ ref('fct_budget_vs_actual_fixed_costs') }}
    group by 1

),

by_type as (

    select
        budget_month,
        actual_amount as type_total
    from {{ ref('fct_budget_vs_actual') }}
    where budget_type = 'Fixed Costs'

)

select *
from by_type
full outer join by_category using ( budget_month )
where abs( coalesce( type_total, 0 ) - coalesce( category_total, 0 ) ) > 0.01
