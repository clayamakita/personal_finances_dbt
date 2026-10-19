with source as (

    select * from {{ source('google_sheets', 'savings_goals') }}

),

cleaned_columns as (

    select
        cast( goal_id as string ) as goal_id,
        cast( goal_name as string ) as goal_name,
        cast( priority as int64 ) as goal_priority,
        {{ parse_sheet_date('initial_target_date') }} as initial_target_date,
        {{ parse_sheet_date('actual_date') }} as actual_date,
        cast( _fivetran_synced as timestamp ) as _loaded_at
    from source

)

select * from cleaned_columns
