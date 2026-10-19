with budget as (

    select * from {{ ref('stg_google_sheets__budget_2026') }}

),

unpivoted as (

    {{ unpivot_budget_months('budget', 2026, ['budget_type']) }}

),

added_key as (

    select
        {{ slug_key(['budget_type'], 'budget_month') }} as budget_month_id,
        budget_type,
        budget_month,
        budget_amount
    from unpivoted
    where budget_type <> 'Guilt-Free Total' 
    -- guilt free total is redundant with the separate guilt free categories

)

select * from added_key
