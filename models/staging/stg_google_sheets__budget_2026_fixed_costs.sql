with source as (

    select * from {{ source('google_sheets', 'budget_2026_fixed_costs') }}

),

cleaned_columns as (

    select
        cast( _row as int64 ) as budget_fixed_costs_id,
        cast( category as string ) as budget_category,
        cast( item as string ) as budget_item,
        cast( january_2026 as numeric ) as january_2026,
        cast( february_2026 as numeric ) as february_2026,
        cast( march_2026 as numeric ) as march_2026,
        cast( april_2026 as numeric ) as april_2026,
        cast( may_2026 as numeric ) as may_2026,
        cast( june_2026 as numeric ) as june_2026,
        cast( july_2026 as numeric ) as july_2026,
        cast( august_2026 as numeric ) as august_2026,
        cast( september_2026 as numeric ) as september_2026,
        cast( october_2026 as numeric ) as october_2026,
        cast( november_2026 as numeric ) as november_2026,
        cast( december_2026 as numeric ) as december_2026,
        cast( _fivetran_synced as timestamp ) as _loaded_at
    from source
    where not (
        category is null
        and item is null
        and january_2026 is null
        and february_2026 is null
        and march_2026 is null
        and april_2026 is null
        and may_2026 is null
        and june_2026 is null
        and july_2026 is null
        and august_2026 is null
        and september_2026 is null
        and october_2026 is null
        and november_2026 is null
        and december_2026 is null
    )
)

select * from cleaned_columns
