with source as (

    select * from {{ source('google_sheets', 'cashflow_transactions') }}

), 

cleaned_columns as (

    select 
        transaction_id, 
        account as account_name, 
        type as transaction_type, 
        category as transaction_category,
        'where' as transaction_location,
        item as transaction_item, 
        cast( amount as numeric ) as transaction_amount, 
        qty as quantity, 
        unit, 
        safe.parse_date( '%d/%b/%Y', date ) as transaction_date, 
        notes,  
        _fivetran_synced as _loaded_at
    from source
)

select * from cleaned_columns