with source as (

    select * from {{ source('google_sheets', 'savings_goals_details') }}
), 

cleaned_columns as (

    select
        goal_detail_id, 
        account as account_name, 
        goal_name, 
        item as goal_item, 
        cast( amount as numeric) as goal_amount, 
        _fivetran_synced as _loaded_at
    from source
)

select * from cleaned_columns