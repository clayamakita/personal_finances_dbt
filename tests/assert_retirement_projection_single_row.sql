{{ config(severity='warn') }}

select count( * ) as row_count
from {{ ref('retirement_projection') }}
having count( * ) <> 1
