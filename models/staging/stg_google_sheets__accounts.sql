with source as (

    select * from {{ source('google_sheets', 'accounts') }}

), 

cleaned_columns as (

    select 
        account_id, 
        account as account_name, 
        account_type, 
        account_category, 
        cast( coalesce( beginning_balance, 0 ) as numeric ) as beginning_balance, 
        cast( coalesce( current_balance, 0 ) as numeric ) as current_balance_sheet, 
    from source

)

select * from cleaned_columns
