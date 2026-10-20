select *
from {{ ref('fct_monthly_paycheck_allocation') }}
where allocation_type = 'Guilt-Free' and allocation_variance <> 0
