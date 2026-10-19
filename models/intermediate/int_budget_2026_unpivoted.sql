with budget as (

    select * from {{ ref('stg_google_sheets__budget_2026') }}

),

unpivoted as (

    {{ unpivot_budget_months('budget', 2026, ['budget_type']) }}
    where budget_type is not null

),

added_key as (

    select
        {{ slug_key(['budget_type'], 'budget_month') }} as budget_month_id,
        budget_type,
        budget_month,
        budget_amount
    from unpivoted
    where budget_type not in ( 'Budget', 'Guilt-Free Total' )
    -- budget is a value used instead of the income to allocate the expenses differently in the source
    -- guilt free total is redundant with the separate guilt free categories

)

select * from added_key
