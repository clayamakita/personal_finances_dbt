with source as (

    select * from {{ source('google_sheets', 'savings_goals_details') }}
),

cleaned_columns as (

    select
        cast( goal_detail_id as string ) as goal_detail_id,
        cast( account as string ) as account_name,
        cast( goal_name as string ) as goal_name,
        cast( item as string ) as goal_item,
        cast( amount as numeric ) as goal_amount,
        cast( _fivetran_synced as timestamp ) as _loaded_at
    from source
)

select * from cleaned_columns
