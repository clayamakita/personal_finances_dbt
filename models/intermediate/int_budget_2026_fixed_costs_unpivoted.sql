with budget as (

    select * from {{ ref('stg_google_sheets__budget_2026_fixed_costs') }}

),
unpivoted as (

    select
        budget_category, 
        budget_item, 
        parse_date('%B %Y', replace(budget_month, '_', ' ')) AS budget_month,
        cast(amount as numeric) AS budget_amount
    from budget
    unpivot(
        amount for budget_month in (
            january_2026, february_2026, march_2026, april_2026, 
            may_2026, june_2026, july_2026, august_2026, 
            september_2026, october_2026, november_2026, december_2026
            )
        )
    where budget_category is not null

)
select * from unpivoted