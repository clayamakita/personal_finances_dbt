select
    _fivetran_synced, 
    _row as budget_id, 
    type as budget_type, 
    cast( coalesce( january_2026, 0 ) as numeric ) as january_2026, 
    cast( coalesce( february_2026, 0 ) as numeric ) as february_2026, 
    cast( coalesce( march_2026, 0 ) as numeric ) as march_2026, 
    cast( coalesce( april_2026, 0 ) as numeric ) as april_2026, 
    cast( coalesce( may_2026, 0 ) as numeric ) as may_2026, 
    cast( coalesce( june_2026, 0 ) as numeric ) as june_2026, 
    cast( coalesce( july_2026, 0 ) as numeric ) as july_2026, 
    cast( coalesce( august_2026, 0 ) as numeric ) as august_2026, 
    cast( coalesce( september_2026, 0 ) as numeric ) as september_2026, 
    cast( coalesce( october_2026, 0 ) as numeric ) as october_2026, 
    cast( coalesce( november_2026, 0 ) as numeric ) as november_2026, 
    cast( coalesce( december_2026, 0 ) as numeric ) as december_2026
from {{ source('google_sheets', 'budget_2026') }}
where not (
    type is null 
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