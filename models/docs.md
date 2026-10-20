{% docs budget_month %}
The first day of the budgeted calendar month (e.g. `2026-01-01`).
{% enddocs %}

{% docs budget_month_id %}
Surrogate key formed by concatenating a slugified `budget_type` (lowercased, with spaces and hyphens removed) with the `budget_month` date, e.g. `guiltfreepet_2026-01-01`. Uniquely identifies a budget_type/budget_month combination.
{% enddocs %}

{% docs budget_type %}
The budget type, e.g. Savings, Investments, Fixed Costs, Income, or one of the individual Guilt-Free types.
{% enddocs %}

{% docs budget_amount_by_type %}
The budgeted dollar amount for this budget_type in this budget_month.
{% enddocs %}

{% docs budget_amount_by_category %}
The budgeted dollar amount for this budget_category in this budget_month.
{% enddocs %}

{% docs cashflow_type %}
High-level cashflow category grouping (e.g., Fixed Costs, Income, Savings, Investments, Transfer, or an individual Guilt-Free allowance).
{% enddocs %}

{% docs _loaded_at %}
Timestamp when data was last successfully synced that specific row.
{% enddocs %}

{% docs is_future_month %}
Boolean flag to show which months are in the future considering the transaction's latest month. Can be used as a filter, so future months aren't shown as "underspent".
{% enddocs %}
