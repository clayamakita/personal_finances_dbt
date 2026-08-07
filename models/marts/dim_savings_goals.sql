with goals as (

    select * from {{ ref('stg_google_sheets__savings_goals') }}

),

goals_details as (

    select * from {{ ref('stg_google_sheets__savings_goals_details') }}

),

accounts as (

    select * from {{ ref('dim_accounts') }}

),

goals_amount as (

    select 
        goals.goal_name, 
        goals.goal_priority, 
        details.account_name, 
        sum( goal_amount ) as goal_amount 
    from goals 
    left join goals_details as details using ( goal_name )
    where goals.goal_priority is not null
    group by 1, 2, 3 

),

goals_accounts_balance as (

    select 
        goals_amount.goal_name, 
        goals_amount.goal_priority, 
        goals_amount.goal_amount, 
        sum( goals_amount.goal_amount ) over( partition by goals_amount.account_name order by goals_amount.goal_priority ) as running_goal_amount, 
        goals_amount.account_name, 
        accounts.current_balance as account_current_balance
    from goals_amount 
    left join accounts using ( account_name )

),

goals_amount_saved as (

    select 
        goal_name, 
        goal_priority, 
        goal_amount, 
        running_goal_amount, 
        account_name, 
        account_current_balance, 
        account_current_balance - ( running_goal_amount - goal_amount ) as account_balance_before, 
        case 
            when account_current_balance - ( running_goal_amount - goal_amount ) <= 0 then 0 
            else least( 
                goal_amount, 
                account_current_balance - ( running_goal_amount - goal_amount )
                )
        end as goal_amount_saved
    from goals_accounts_balance
),

goals_status as (

    select 
        goal_name, 
        goal_priority, 
        goal_amount, 
        running_goal_amount, 
        account_name, 
        account_current_balance, 
        goal_amount_saved, 
        case
            when goal_amount_saved = goal_amount then 'Achieved' 
            when goal_amount_saved > 0 then 'In Progress' 
            else 'Not Started'
        end as goal_status, 
        case
            when goal_amount_saved = goal_amount then 1  
            else 2
        end as goal_status_id,
        case 
            when goal_amount_saved = goal_amount then 0 
            else goal_amount - goal_amount_saved 
         end as goal_amount_needed
    from goals_amount_saved
)

select * from goals_status