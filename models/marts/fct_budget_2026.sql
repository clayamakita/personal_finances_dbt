with budget as (

    select * from {{ ref('int_budget_2026_unpivoted') }}

), 

added_key as (

    select
        replace( budget_type, ' ', '_' ) || '-' || cast( budget_month as string ) as budget_fct_id,
        budget_type, 
        budget_month, 
        budget_amount
    from budget

)

select * from added_key