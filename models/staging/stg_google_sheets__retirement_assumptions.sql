with source as (

    select * from {{ source('google_sheets', 'retirement_assumptions') }}

),

selected_columns as (

    select 
        current_age, 
        retirement_age, 
        projected_interest_rate
    from source
)

select * from selected_columns