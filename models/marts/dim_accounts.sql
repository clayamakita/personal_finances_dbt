with accounts as (

    select * from {{ ref('int_accounts') }}

), 

final as (

    select 
        account_id, 
        account_name,
        account_type, 
        account_category, 
        beginning_balance, 
        current_balance
    from accounts

)

select * from final
