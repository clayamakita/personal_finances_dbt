with type_category as (

    select * from {{ ref('stg_google_sheets__cashflow_type_category') }}

),

selected_columns as (

    select  
        distinct cashflow_type
    from type_category

), 

added_key as (

    select 
        "flowtype" || lpad( cast( row_number() over() as string ), 2, "0" ) as cashflow_type_id, 
        cashflow_type
    from selected_columns
        
)

select * from added_key