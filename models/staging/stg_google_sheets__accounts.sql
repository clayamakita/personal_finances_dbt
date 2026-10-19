with source as (

    select * from {{ source('google_sheets', 'accounts') }}

),

cleaned_columns as (

    select
        cast( account_id as string ) as account_id,
        cast( account as string ) as account_name,
        cast( account_type as string ) as account_type,
        cast( account_category as string ) as account_category,
        cast( coalesce( beginning_balance, 0 ) as numeric ) as beginning_balance,
        cast( coalesce( current_balance, 0 ) as numeric ) as current_balance_sheet,
        cast( _fivetran_synced as timestamp ) as _loaded_at
    from source

)

select * from cleaned_columns
