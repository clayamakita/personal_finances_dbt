with source as (

    select * from {{ source('google_sheets', 'retirement_assumptions') }}

),

final as (

    select
        cast( current_age as int64 ) as current_age,
        cast( retirement_age as int64 ) as retirement_age,
        cast( projected_interest_rate as float64 ) as projected_interest_rate
    from source
)

select * from final
