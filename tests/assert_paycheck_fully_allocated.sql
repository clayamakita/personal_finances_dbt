{{ config(severity='warn') }}

with allocation as (

    select
        budget_month,
        sum( if( allocation_type = 'Paycheck', allocation_amount, 0 ) ) as paycheck,
        sum( if( allocation_type <> 'Paycheck', allocation_amount, 0 ) ) as allocated
    from {{ ref('fct_monthly_paycheck_allocation') }}
    where budget_month < date_trunc( {{ today() }}, month )
    group by 1

)

select
    budget_month,
    paycheck,
    allocated,
    paycheck - allocated as unallocated
from allocation
where paycheck - allocated > 0.01
