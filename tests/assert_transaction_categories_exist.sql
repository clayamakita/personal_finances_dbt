{{ config(severity='warn') }}

select
    transactions.transaction_type,
    transactions.transaction_category
from {{ ref('fct_cashflow_transactions') }} as transactions
left join {{ ref('dim_cashflow_categories') }} as categories
    on
        transactions.transaction_type = categories.cashflow_type
        and transactions.transaction_category = categories.cashflow_category
where categories.cashflow_category is null
group by 1, 2
