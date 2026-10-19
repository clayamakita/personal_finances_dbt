with budget as (

    select * from {{ ref('stg_google_sheets__budget_2026_fixed_costs') }}

),

unpivoted as (

    {{ unpivot_budget_months('budget', 2026, ['budget_category', 'budget_item']) }}

),

added_key as (

    select
        {{ slug_key(['budget_item'], 'budget_month') }} as budget_fixed_costs_item_id,
        budget_category,
        budget_item,
        budget_month,
        budget_amount
    from unpivoted

)

select * from added_key
