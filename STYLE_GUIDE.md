# Style Guide — `personal_finances` dbt project

Standards for how this project is structured, written, tested and documented. The goal is that any model can be read, reviewed and extended without having to guess the conventions.

**Stack:** dbt Cloud (Studio IDE, v1 Latest release track) on BigQuery · Fivetran → Google Sheets sources · dbt_utils

Words used in this guide: **must** = enforced in review or CI, **should** = default unless there's a reason, **may** = optional.

The initial project decisions (key format, datasets, currency, timezone) are recorded in `ADOPTION_PLAN.md` and reflected below.

---

## 1. Project structure

```
models/
  staging/google_sheets/   stg_google_sheets__<source_table>.sql + _stg_google_sheets.yml
                           _src_google_sheets.yml
  intermediate/            int_<entity>_<verb/description>.sql + _int.yml
  marts/                   dim_*, fct_*, and reporting models + _marts.yml
macros/
tests/                     singular tests (reconciliation, business rules)
```

### Layer responsibilities

| Layer | Does | Must not | Materialization |
|---|---|---|---|
| **Staging** | 1:1 with a source table. Rename, cast, parse dates, drop truly empty rows. | Join, aggregate, apply business rules, `coalesce` nulls to 0 unless null genuinely means zero. | view |
| **Intermediate** | Joins, unpivots, aggregations, key creation, reusable business logic. | Be exposed to consumers. | view |
| **Marts** | Business-facing `dim_`, `fct_` and reporting models with a stated grain. | Contain logic that belongs in a reusable intermediate model. | table |

### Reference rules

- `source()` appears **only** in staging models.
- Staging models are only referenced by intermediate models and by marts that are pure pass-throughs (see 8.3).
- Marts may reference intermediate models and other marts. Intermediate models must not reference marts.
- No model references a model in a later layer.
- Every model has exactly one stated **grain**, written in its description.

> **Decided:** marts may `ref` staging directly only for pass-throughs with no transformation.

---

## 2. Naming

### Models

| Layer | Pattern | Example |
|---|---|---|
| Source YAML | `_src_<source>.yml` | `_src_google_sheets.yml` |
| Staging | `stg_<source>__<source_table>` (double underscore, name matches the source table exactly) | `stg_google_sheets__investments_price` |
| Intermediate | `int_<entity>_<description>` | `int_cashflow_transactions_agg_month` |
| Dimension | `dim_<entity>` (plural) | `dim_accounts` |
| Fact | `fct_<process>` (describes events or measurements) | `fct_cashflow_transactions` |
| Reporting / single-row | `rpt_<description>` | `rpt_retirement_projection` |

- Names are lowercase `snake_case`. No abbreviations other than `int`, `stg`, `dim`, `fct`, `rpt`, `agg`.
- Year-specific models carry the year (`int_budget_2026_unpivoted`). The combined model has no year (`int_budget`).
- A model's file name, `name:` in YAML and `ref()` target are always identical.

### Columns

| Kind | Rule | Example |
|---|---|---|
| Primary key | `<entity>_id` | `account_id`, `transaction_id` |
| Foreign key | same name as the key it references | `account_id` |
| Date | `<event>_date`, type `DATE` | `transaction_date`, `event_date` |
| Month | `<event>_month`, `DATE` = **first day of the month** | `budget_month`, `transaction_month` |
| Timestamp | `<event>_at`, `TIMESTAMP` | `_loaded_at` |
| Money | `<thing>_amount` | `budget_amount`, `actual_amount` |
| Count / units | `quantity`, `total_quantity` (never `qty`) | |
| Rate | `<thing>_rate`, stored as a decimal (0.07 = 7%) | `annualized_return_rate` |
| Running total | prefix `running_` | `running_budget_amount` |
| Boolean | `is_` / `has_` prefix | `is_closed_month` |
| Metadata | leading underscore | `_loaded_at` |

- Use `date`, not `timestamp`, wherever time of day doesn't matter.
- Don't use the raw source name when a clearer one exists, but rename **once, in staging**, and keep the name from there on.
- Prefer ID joins over name joins. Names (`account_name`) are attributes, not keys.

---

## 3. Data conventions

These apply to every model and are the main reason this section exists: the same number can be "right" or "wrong" depending on convention.

1. **Sign of money in transaction facts:** negative = money out, positive = money in (`transaction_amount`).
2. **Sign in comparison facts:** `actual_amount` and `allocation_amount` are absolute values. `variance_amount` is signed so that **positive is favorable**:
   - Inflow-type buckets (Income/Paycheck, Investments, Savings): `actual − budget`
   - Outflow-type buckets (Fixed Costs, Guilt-Free): `budget − actual`
   - Which types are inflow-type is defined **once** (macro or `dim_cashflow_types` attribute), never retyped in a model.
3. **Currency:** CAD. No currency column unless a second currency is introduced.
4. **Rounding:** do not round in staging or intermediate. Round only in marts, and only for presentation (2 decimals for money, 4 for rates).
5. **Time zone:** one project variable (`var('project_timezone')`, default `America/Toronto`) used for every `current_date()` call. Never call `current_date()` directly: use the `today()` macro, which wraps it with the project timezone (and can be overridden in unit tests).
6. **"Latest month"** is defined in one place only (`int_budget_latest_month`, driven by the latest transaction month). Other models consume it; they don't redefine it.
7. **Future months:** budgeted months with no transactions yet are not "underspent". Comparison facts should carry an `is_closed_month` flag (or exclude open months).
8. **Calendar:** every month/year-level join uses `dim_dates` or a first-of-month `DATE`, never strings.
9. **Income:** all income, including bonuses and extra paychecks, is recorded with category `Paycheck`. A bonus then shows up as a positive Paycheck variance in `fct_monthly_paycheck_allocation`, and a test fails if income is recorded under any other category.
10. **Guilt-Free carry-over:** unspent Guilt-Free budget carries over across months and years, so Guilt-Free running totals are cumulative since the first month in the data and never reset.

---

## 4. SQL style

Enforced with `sqlfluff` (dialect `bigquery`): the Lint and Fix buttons in the dbt Cloud IDE while you work, and the lint step of the dbt Cloud CI job on every PR. Formatting should never be argued about in review.

- Lowercase keywords and functions. Lowercase `as`.
- 4-space indent. No trailing whitespace. One column per line, leading definitions aligned.
- Standard shape: **import CTEs → logic CTEs → `final`**.
  - Import CTEs: `select * from {{ ref(...) }}` (or `source()` in staging), one per upstream model, named for the model.
  - Logic CTEs: one transformation each, named for what it does (`aggregated_month`, `added_key`).
  - Last CTE is always named `final`, followed by `select * from final`.
- Use `select *, <new_columns>` when a CTE only adds columns, instead of re-listing the whole column list in every step.
- Group by column name, not position, except in a one-line aggregation.
- Joins are explicit (`left join`, `inner join`), use aliases that mean something, and `using` only for single-key joins.
- No `order by` in a model unless it is required by a window function.
- Comments explain **why** (a business rule, a source quirk), not what. Every hardcoded business value (like a `+ 1` month buffer) gets a comment.
- Hardcoded lists of categories or types belong in a macro, seed or dimension, not inline.
- BigQuery-specific syntax (`safe.parse_date`, `unpivot`, backtick quoting, `date_trunc(x, month)`) is allowed but stays in the layer that needs it. Mention BigQuery in the README.

---

## 5. Layer rules in detail

### 5.1 Staging

- One model per source table, 1:1. Same row grain as the source.
- Allowed: rename, explicit `cast`, date parsing, dropping rows where every column is null, `_fivetran_synced as _loaded_at`.
- **Every column gets an explicit type**, including IDs and numbers. Don't rely on inferred types.
- **Date parsing goes through one macro** (`parse_sheet_date(column)`), not repeated inline.
- **Null handling:** don't `coalesce` blanks to 0 by default. A blank cell and a true 0 mean different things. Coalesce only where null genuinely means zero (e.g. `dividends`), and say so in a comment.
- Blank-row cleanup happens in staging, not in a later layer.
- Keep a source's quirks out of later layers: if the sheet has a subtotal row, drop or flag it here.
- Every staging model has `_loaded_at`, and the end CTE is `final`.
- Don't use `_row` as a business key. If a row number is the only ID available, document the risk (reordering the sheet changes IDs) in the column description.

### 5.2 Intermediate

- One purpose per model, named for it. If a model's name needs "and", split it.
- Surrogate keys come from **one macro** (`slug_key`), not hand-built string concatenation. Keys are **human-readable**: each part lowercased with spaces and hyphens removed, parts joined with `_`, dates in ISO format (e.g. `guiltfreepet_2026-01-01`, `guiltfreepet_boarding_2026-02-01`). Readable keys are a deliberate choice for this project, so don't switch to hashed keys without recording the change in an ADR.
- Unpivots use a shared macro (`unpivot_budget_months(relation, year)`), so adding a year is a single call.
- Yearly models are combined in one stable `int_<thing>` model. Downstream models only ever reference the combined model (see the checklist in section 11).
- Exclusions (e.g. non-budget rows) are filtered **before** expensive reshaping, with a comment saying why.
- Models are views, so logic must stay cheap. If one becomes slow or heavily reused, promote it deliberately and note why.

### 5.3 Marts

- Each mart is one of: **dimension** (describes an entity, one row per entity), **fact** (one row per event or measurement), or **reporting** (derived, single-purpose).
- State the grain in the first sentence of the description, and test it (`unique` or `unique_combination_of_columns`).
- Facts carry **keys** to dimensions (`account_id`, `date_id`/month date, category ids), not just names.
- Don't put derived projections or metrics in `dim_` models; put them in a `fct_` or `rpt_` model. **Documented exceptions:** `dim_savings_goals` (funding status and projected funding month) and `dim_investments` (XIRR return). Each stays one row per entity and states the exception in its description. Any new exception needs an ADR.
- Pass-through marts (`select` of one upstream model) are allowed as the **stable public interface**, since consumers only ever reference marts. They must be marked `access: public` and listed as such.
- Column order: keys, descriptors, measures, flags.

---

## 6. Testing

### 6.1 Minimum per model

| Always | When |
|---|---|
| Primary key: `unique` + `not_null` | Every model (use `unique_combination_of_columns` for composite grain) |
| `not_null` | Every column that must never be blank |
| `relationships` | Every foreign key (facts → dims, transactions → accounts) |
| `accepted_values` | Closed enumerations, **at the layer where the value set is defined** |
| Source freshness | Every source with a `_fivetran_synced` column |

### 6.2 Where tests live

- Test a property **once**, where it is introduced, and again only where a transformation could break it. Don't repeat the same `accepted_values` list at every layer.
- Prefer a `relationships` test to the reference table (`cashflow_type_category`) over a copy-pasted `accepted_values` list, so there is one source of truth.
- Keep `where:` filters on conditional tests explicit and documented.

### 6.3 Reconciliation tests (singular, in `tests/`)

These protect the numbers that matter. At minimum:

- Fixed-cost category budgets sum to the `Fixed Costs` budget for the same month. Same for actuals.
- Account balances: `current_balance` (dbt) = `current_balance_sheet` (sheet), within a tolerance.
- Paycheck allocation: Paycheck = Fixed Costs + Savings + Investments + Guilt-Free + Unallocated.
- Guilt-Free `allocation_variance` is always 0.
- Every transaction category appears in `dim_cashflow_categories`.
- `retirement_projection` has exactly 1 row.

### 6.4 Unit tests

Required for non-trivial logic: the savings-goal waterfall, `months_to_goal`, the future-value formula (including a 0% rate), the Guilt-Free override, and XIRR edge cases.

### 6.5 Severity

- Failing PK, FK, reconciliation and freshness-error tests **block** merging.
- Source data-quality tests on manually entered sheets may be `severity: warn`, with a comment saying why.

---

## 7. Documentation

- Every model **and every column** has a description. No empty or copy-pasted descriptions.
- **Model descriptions** start with the grain: *"One row per account."* Then purpose, then any business rule or assumption.
- **Column descriptions** say what it is, the unit/sign/format where relevant, and an example if it's an enum.
- Description for a derived column states the formula in words.
- Reused descriptions (`budget_month`, `budget_type`, `_loaded_at`, etc.) live in `docs/*.md` doc blocks and are referenced with `{{ doc('...') }}`.
- Descriptions must be accurate for **that model**. Don't leave "budget_type" in a model that uses `budget_category`.
- Business rules and assumptions are documented where they live: the `+ 1` month buffer, the Guilt-Free override, "latest month" definition, the retirement projection assumptions (nominal return, no inflation, no tax, constant contribution).
- Turn on `persist_docs` so descriptions appear in BigQuery.
- YAML files: one per layer folder, with a consistent header, 2-space indent, no trailing spaces, models in the same order as the DAG flows.
- Proofread. Typos in descriptions are shipped documentation.

---

## 8. Configuration & governance

- `dbt_project.yml` sets materialization and schema **per layer folder**. Model-level `config()` is only for exceptions, with a comment.
- **Each layer builds into its own dataset:** `staging`, `intermediate`, `marts`. The `generate_schema_name` macro is overridden so the Production environment (deployment type Production, `DBT_CLOUD_ENVIRONMENT_TYPE` = `prod`) uses these clean names, while the IDE and CI prefix them (e.g. `dbt_<you>_marts`, `dbt_cloud_pr_123_456_marts`). The macro must keep the `dbt_cloud_pr_` prefix on CI schemas so dbt Cloud can drop them when a PR closes. Raw data stays in `src_google_sheets`.
- Pin package versions in `packages.yml`. The dbt version is managed by the dbt Cloud environment's release track (v1 Latest), so `require-dbt-version` isn't used.
- Marts use **enforced contracts** (`contract: {enforced: true}`) with declared `data_type`s, so the "stable interface" claim is mechanically true.
- `access: public` for marts, `protected` for staging and intermediate where supported.
- Hidden dependencies are avoided. Anything the DAG can't see (e.g. a function created in an `on-run-start` hook) is documented in the README and, where supported, modelled as a proper project resource.
- No secrets in the repo. The BigQuery project ID in `sources` comes from an `env_var` or project var, not a literal.
- Tags and `meta` identify owner and purpose (e.g. `meta: {owner: ..., domain: budget}`).
- Define **exposures** for anything consumed outside dbt (dashboards, the retirement view).

---

## 9. Git & review workflow

- Work on a branch, open a PR, squash-merge to `main`.
- Commit messages follow Conventional Commits: `<type>(<scope>): <imperative subject>` (e.g. `refactor(staging): use parse_sheet_date`). Types: `feat`, `fix`, `refactor`, `style`, `test`, `docs`, `chore`, `ci`. Mark breaking changes with `!`.
- Linting runs in the IDE (Lint, Fix and Format buttons). The dbt Cloud CI job runs on every PR: SQL linting, `dbt build --select state:modified+` deferring to Production, and `dbt_project_evaluator`.
- Every PR answers the **review checklist** (section 10).
- Non-obvious design decisions get a short ADR in `docs/decisions/` (e.g. *why budgets are unpivoted per year*).

---

## 10. PR review checklist

**Structure**
- [ ] Model is in the right layer and follows the reference rules
- [ ] Name follows the pattern; grain stated and tested
- [ ] No logic that already exists in a macro or another model

**SQL**
- [ ] Passes `sqlfluff`; import → logic → `final` shape
- [ ] No hardcoded lists, dates or magic numbers without a comment or macro
- [ ] Types are explicit; nulls handled deliberately
- [ ] Time-dependent logic uses the project timezone var

**Data**
- [ ] Sign and rounding conventions followed (section 3)
- [ ] Joins can't silently drop or fan out rows (checked, or a `relationships` / row-count test added)
- [ ] Future/open months handled

**Tests & docs**
- [ ] PK, FK and enum tests present at the right layer
- [ ] Reconciliation or unit test added for new business logic
- [ ] Model and every column documented, accurately and without typos
- [ ] README / ADR updated if behavior changed

---

## 11. New budget year checklist

When a new year's budget sheet is added (e.g. 2027):

1. Add the new source table(s) to `_src_google_sheets.yml` and a `freshness` config.
2. Create `stg_google_sheets__budget_2027` and `stg_google_sheets__budget_2027_fixed_costs`.
3. Create the year's unpivoted intermediate models by calling the unpivot macro. Don't copy-paste the SQL.
4. Add the year's models to the **union in `int_budget` and `int_budget_fixed_costs`**. Don't change any downstream reference.
5. Confirm `dim_dates` covers the year, since its range comes from the data.
6. Run the reconciliation tests. Check there are no duplicate `budget_type` + `budget_month` combinations across years.
7. Update descriptions that mention a specific year.

---

## Appendix A — Adoption backlog

Existing code that doesn't yet meet this guide. Group into PRs by theme.

**Correctness (do first)**
- [ ] `fct_monthly_paycheck_allocation`: test that all income is categorized `Paycheck`; apply the Guilt-Free override in `final`; fix `like 'Guilt-Free'`; drop dead filters and `order by`
- [ ] `dim_cashflow_types`: replace the `row_number()` key with `slug_key`
- [ ] `dim_savings_goals`: use `rows between unbounded preceding and current row`; add `unique` test on priority; align "now" with `int_budget_latest_month`; document the `+ 1` buffer and sequential-funding assumption
- [ ] Comparison facts: `is_closed_month` flag; correct the guilt-free "year-to-date" wording (running totals carry over across years)
- [ ] `fct_budget_vs_actual_fixed_costs`: reconciliation and `relationships` tests so unbudgeted spend isn't dropped silently
- [ ] `int_accounts`: `relationships` test from transaction accounts; add to `_int.yml`
- [ ] `int_investments_current_position`: `unique` test on `ticker`; confirm Dividends handling
- [ ] `dim_dates`: end date from the max across all sources; add a month-start column

**Consistency**
- [ ] Replace repeated `accepted_values` with `relationships` to the reference table; reconcile `Savings Spending` mismatch
- [ ] One surrogate-key macro; one unpivot macro; one date-parse macro
- [ ] Rename `investments_prices` / `investments_price` so they match
- [ ] Standardize last CTE name to `final`; add `_loaded_at` to `retirement_assumptions`
- [ ] Null handling: stop coalescing budget and account values to 0; add source-level null tests
- [ ] Move empty-row filtering for the fixed-costs budget into staging
- [ ] Single timezone var replacing `current_date()` and `current_date('America/Toronto')`
- [ ] Rename `monthly_rate` to a growth-factor name in `retirement_projection`; handle 0% rate; remove meaningless `limit 1`

**Structure & governance**
- [ ] Rename `retirement_projection` to follow the `rpt_` pattern; document the derived-metrics exception in `dim_savings_goals` / `dim_investments`
- [ ] Add facts → dimension keys (`account_id`, `date_id`, category IDs) and `relationships` tests
- [ ] Per-layer `+schema`, `persist_docs`, remove `dbt init` template comments
- [ ] Enforced contracts on marts; exposures; tags/meta
- [ ] Make the `calculate_annualized_return()` hook visible (docs, or a modelled resource if supported)
- [ ] Source `database:` from `env_var` or a project var, since the repo is public
- [ ] Add `.sqlfluff` and `.sqlfluffignore`, a Production environment with a baseline job, a dbt Cloud CI job and `dbt_project_evaluator`
- [ ] Fix typos and copy-paste descriptions (`transaction_month`, fixed-costs `budget_amount`, etc.)
- [ ] Tidy YAML (consistent header, indent, trailing spaces)
