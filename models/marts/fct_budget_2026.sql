with budget as (

    select * from {{ ref('int_budget_2026_unpivoted') }}

), 

added_key as (

    select
        {{ dbt_utils.generate_surrogate_key(['budget_type', 'budget_month']) }} as budget_unpivoted_id,
        budget_type, 
        budget_month, 
        budget_amount
    from source

)

select * from added_key