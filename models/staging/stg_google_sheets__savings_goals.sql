with source as (

    select * from {{ source('google_sheets', 'savings_goals') }}

),

cleaned_columns as (

    select 
        goal_id, 
        goal_name, 
        priority as goal_priority, 
        safe.parse_date( '%d/%b/%Y', initial_target_date ) as initial_target_date, 
        safe.parse_date( '%d/%b/%Y', actual_date ) as actual_date, 
        _fivetran_synced as _loaded_at
    from source
    
)

select * from cleaned_columns