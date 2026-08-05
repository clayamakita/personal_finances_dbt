with budget as (

    select * from {{ ref('int_budget_2026_unpivoted') }}

), 

added_key as (

    select
        {{ dbt_utils.generate_surrogate_key(['budget_type', 'budget_month']) }} as fct_budget_id,
        budget_type, 
        budget_month, 
        budget_amount
    from budget

)

select * from added_key