with assumptions as (

    select * from {{ ref('stg_google_sheets__retirement_assumptions') }}

),

current_position as (

    select * from {{ ref('int_investments_current_position') }}

),

budget_latest_month as (

    select * from {{ ref('int_budget_latest_month') }}

),

budget_latest_month_investments as (

    select 
        budget_amount 
    from budget_latest_month 
    where budget_type = 'Investments' 
    limit 1

),

total_current_position as (

    select
        sum( current_value ) as current_value 
    from current_position

),

joined_tables as (

    select 
        position.current_value, 
        assumptions.current_age, 
        assumptions.retirement_age, 
        assumptions.projected_interest_rate, 
        assumptions.retirement_age - assumptions.current_age as contribution_years, 
        budget.budget_amount as monthly_contribution
    from total_current_position as position 
    cross join assumptions
    cross join budget_latest_month_investments as budget
),

added_compound_growth_rate as (

    select 
        current_value, 
        current_age, 
        retirement_age, 
        projected_interest_rate, 
        contribution_years, 
        monthly_contribution, 
        power( 1 + ( projected_interest_rate / 12 ), contribution_years * 12 ) as monthly_rate
    from joined_tables
), 

added_future_value as (

    select 
        current_value, 
        current_age, 
        retirement_age, 
        projected_interest_rate, 
        monthly_contribution, 
        round(
            current_value * monthly_rate 
            + ( 12 * monthly_contribution * ( monthly_rate - 1 )  / nullif( projected_interest_rate, 0 ) ), 
            2
        ) as future_value
    from added_compound_growth_rate

)

select * from added_future_value