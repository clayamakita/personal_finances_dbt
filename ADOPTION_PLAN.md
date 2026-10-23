# Adoption Plan — `personal_finances` dbt project

Step-by-step plan for bringing the project in line with `STYLE_GUIDE.md`: what to change, in what order, and how to branch and commit it.

---

## Where things stand (updated 23 Oct 2026)

| Step | Status |
|---|---|
| Phase 0: PR-01, PR-02 and the Baseline step | Done |
| Phase 1: PR-03 | Done |
| Phase 2: PR-04, PR-05 | Done |
| Phase 3: PR-06 to PR-10 | Done |
| Phase 4: PR-11, PR-13 | Done |
| PR-12 (source freshness) | Moved: now after the data feed, see the Interlude |
| Phase 5: PR-14, PR-15, PR-16 | Done |
| PR-16a (baseline helper tweak) | New, in the Interlude |
| Task G (sheet data generator) | New, in the Interlude. Script written: install it and check the results |
| PR-17 to PR-22 | Next |
| Phase 6: PR-23 to PR-28 | Pending |
| PR-29 (CI) and PR-30 (README and ADRs) | Pending |

**Order from here:** PR-16a, then Task G, then PR-12, then PR-17 to PR-22 (release v1.1.0), then PR-23 to PR-28 (release v2.0.0), then PR-29 and PR-30.

**What changed in this version of the plan**

- New **Interlude** between PR-16 and PR-17: PR-16a, Task G (the Apps Script data generator) and PR-12, moved there and rewritten.
- Details we settled while you worked now sit in the PRs: doc blocks in PR-04, cast rules and the `final` CTE note in PR-09, the keep-or-delete table for `accepted_values` in PR-11.
- The Baseline "data moves" catch, PR-25, PR-29, PR-30 and Tracking were updated for the data feed, the README you already published, and freshness.

---

## 0. Working in the dbt Cloud IDE

This plan was first written for dbt Core with a terminal. You work only in the dbt Cloud IDE (called *Studio* in dbt's docs), so every step has been adapted. Button labels can differ slightly between dbt Cloud versions; the idea of each step stays the same.

### What changes compared with a terminal setup

| Terminal approach | In the dbt Cloud IDE |
|---|---|
| `dbt build --target dev` | `dbt build` in the **command bar**, with the **Defer** menu set to **Development** |
| `profiles.yml` targets (`dev`, `baseline`, `prod`) | dbt Cloud **environments**: Development (the IDE), Production (the baseline, later the real pipeline), CI |
| `pip install sqlfluff`, `sqlfluff lint` / `fix` | Built-in **Lint**, **Fix** and **Format** buttons, configured by `.sqlfluff` and `.sqlfluffignore` |
| `grep` | **Search for Text** (Cmd/Ctrl+P), with search and replace |
| `git switch`, `git commit`, `git push` | The **Git actions** button: Create new branch, Commit and sync, Open pull request |
| `git tag` | A **release** on GitHub |
| pre-commit hooks, GitHub Actions | The IDE's Lint button while you work, and a **dbt Cloud CI job** on every pull request |
| Queries in the BigQuery console | **Preview** in the IDE (or the console, if you prefer) |
| Comparing compiled SQL folders with `diff` | The **Compile** tab for single models, and the `audit_helper` data comparison |

### What the IDE can't do

- There is no terminal: no `pip`, `grep`, `git` or `sqlfluff` commands. Only dbt commands run in the command bar.
- `main` is protected in the IDE. You can't commit to it, so every change starts on a branch.
- Merging, deleting branches and releases happen on GitHub.
- A development session times out after an hour idle. Commit often, so nothing is lost.

### Environments you'll use

| Environment | Used for | Dataset | Created in |
|---|---|---|---|
| Development (the IDE) | your builds while you edit | your own development dataset (shown in Account settings → Credentials) | already exists |
| Production (deployment type **Production**) | the baseline built from `main`, later the real pipeline | for example `analytics` | Phase 0 (Baseline step) |
| CI (deployment) | builds each pull request | temporary schemas named `dbt_cloud_pr_<job>_<pr>` | PR-29 |

### Two habits to keep

- **Defer.** The command bar's Defer menu decides where unchanged upstream models are read from. For every comparison with the baseline, choose **Development** (defer off), so the whole project builds into your dev dataset. With defer on, the comparison would read Production against Production and prove nothing.
- **Ad hoc SQL.** **Preview** runs the SQL in the active editor, saved or not, and shows up to 500 rows (write an explicit `limit`). It runs a **single statement**. For one-off queries, create a scratch file in `analyses/`, click Preview, then revert or delete the file before you commit.

---

## 1. Why this order

1. **Safety net first.** Add the tooling and capture a baseline before touching any logic, so every later change can be checked against known-good output.
2. **Formatting alone, early.** The auto-format touches almost every line. Doing it in its own PR keeps every later diff small and reviewable.
3. **Behavior-preserving changes before behavior-changing ones.** Refactors (macros, config, docs) must produce identical data. Bug fixes change data on purpose. Never mix the two in one PR, or you can't tell which caused a difference.
4. **Tests before fixes, fixes test-first.** New tests start as `warn` so they don't block you, and are promoted to errors once the underlying bug is fixed.
5. **Breaking changes last, grouped.** Renames and key changes touch many files and any consumer of the marts, so batch them and tag a new major version.
6. **CI and polish at the end**, once the project is stable enough to enforce.

Each phase ends with a `dbt build` that passes and (for phases 1-3) a data comparison showing **zero differences**.

---

## 2. Git workflow

### Branches

One branch per concern, named `<type>/<short-kebab-description>`.

| Type | Use for | Example |
|---|---|---|
| `docs/` | README, descriptions, guides, ADRs | `docs/style-guide` |
| `chore/` | Tooling, config, packages | `chore/dev-tooling` |
| `style/` | Formatting only, zero logic | `style/sqlfluff-format` |
| `refactor/` | Behavior-preserving restructuring | `refactor/parse-sheet-date-macro` |
| `fix/` | Behavior-changing bug fix | `fix/paycheck-allocation` |
| `test/` | Adding tests only | `test/relationships` |
| `feat/` | New capability | `feat/mart-contracts` |
| `ci/` | Pipelines and automation | `ci/github-actions` |

Rules:

- Branch from an up-to-date `main`. Merge **one PR at a time**, then branch the next one from the new `main`. Don't stack branches.
- Keep each branch small enough to review in one sitting. If a PR needs the word "and", split it.
- Delete the branch after merging.

### Commits (Conventional Commits)

```
<type>(<scope>): <imperative subject, max ~72 chars>

<optional body: why, not what>
```

- **Types:** `feat`, `fix`, `refactor`, `style`, `test`, `docs`, `chore`, `ci`.
- **Scopes:** `staging`, `int`, `marts`, `macros`, `tests`, `config`, `docs`, `ci`, or a model name.
- One logical change per commit. Each commit should leave the project buildable.
- Mark breaking changes with `!` and a `BREAKING CHANGE:` line in the body, e.g. `refactor(marts)!: rename retirement_projection to rpt_retirement_projection`.

### Test-first pattern for fixes

Every `fix/` branch has at least two commits:

1. `test(<scope>): add failing test for <problem>`: the test fails on current code.
2. `fix(<scope>): <what changed>`: the test now passes.

(If the test would break the build between commits, add it with `severity: warn` in commit 1 and promote it in commit 2.)

### Pull requests

- **Title:** the PR title follows the commit format (`<type>(<scope>): <subject>`, with `!` for breaking changes). It becomes the squash-merge commit message, so it is the one line `main`'s history will show for the whole PR. Describe the PR as a whole, not one commit.
- **Description:** four headings, in this order: **What changed**, **Why**, **How I verified it**, **Does data change?** (if it does: which rows or columns, and why that's expected).
- **Ready-made text:** every PR in section 4 ends with a suggested title and description. Paste them into GitHub when you open the PR and edit anything that differs from what you actually did. Text in [brackets] is a result only you can fill in.
- **Template:** PR-29 adds `.github/pull_request_template.md`, so from then on GitHub pre-fills the four headings.
- Squash-merge to `main`. In the merge dialog, check that the title is still right and trim any clutter from the body.

### Special cases

- **Versions:** the `version` in `dbt_project.yml` is bumped and released at milestones: `v1.1.0` after phase 5 (fixes), `v2.0.0` after phase 6 (breaking interface changes). Once the version-bump PR has merged, publish a release on GitHub (**Releases → Draft a new release → Choose a tag**, type the new tag name and pick **Create new tag on publish**, target `main`). GitHub creates the tag for you.
- **Never** mix formatting, refactoring and logic changes in one commit.

### How to verify a PR

- Build the branch in the IDE: set **Defer** to **Development**, then run `dbt build` in the command bar.
- **Behavior-preserving PRs:** compare your dev build with the baseline using `analyses/compare_to_baseline.sql` (PR-02, Part 3). Every row must match.
- **Behavior-changing PRs:** the diff must match what the PR description says should change, and nothing else.

### The routine for every PR

1. **Start clean.** Git actions button → **Change branch** → `main` → **Pull from remote** (offered when `main` is behind). Then **Create new branch** and enter the branch name. `main` is protected, so you can't commit to it.
2. **One logical change at a time.** Edit, save, then **Commit and sync** with a Conventional Commit message. To commit only some files, right-click the file in the Changes list. Repeat. (Keep detail for the PR description: the plan only relies on the first line of each commit message.) Scratch files for ad hoc queries must not be committed: revert or delete them first.
3. **Build and test in your development environment.** In the command bar's **Defer** menu choose **Development** (defer off), then run `dbt build --exclude package:dbt_project_evaluator`. Run `dbt deps` first if `packages.yml` changed. If you leave defer on, unchanged upstream models are read from Production and a comparison with the baseline proves nothing.
4. **Lint what you touched.** Open each changed SQL file → **Lint** → read the **Code quality** tab → **Fix** what can be fixed. For YAML and Markdown, use **Format**. Lint doesn't rerun on save.
5. **Behavior-preserving PRs only: compare with the baseline** (see the Baseline step in Phase 0):
   1. If `main` changed since the last baseline run, run the job **Baseline: build main** (**Orchestration → Jobs →** the job **→ Run now**) and wait for it to succeed.
   2. Open `analyses/compare_all_to_baseline.sql` and click **Preview**. An empty result means every model matches the baseline. If rows appear, note which models differ, then open `analyses/compare_to_baseline.sql`, set `model_name`, `primary_key` (and `excluded_columns` if needed) and click **Preview** to see which rows differ.
6. **Open the PR.** Git actions → **Open pull request** (this takes you to GitHub). Paste the PR title and description from the PR's block in section 4 (the title becomes the squash-commit message), and edit them to match what you did. Every description uses the same four headings:
   ```
   ## What changed
   ## Why
   ## How I verified it
   ## Does data change? (if yes: which rows/columns, and why that's expected)
   ```
   From PR-29 on, the dbt Cloud CI job runs automatically on the PR; wait for it to pass.
7. **Merge and clean up.** Squash and merge on GitHub, then click **Delete branch**. Back in the IDE: **Change branch** → `main` → **Pull from remote**, and use **Prune branches** in the Git actions menu to remove the deleted branch. Run **Baseline: build main** again so Production matches `main`.

**Ad hoc SQL.** **Preview** runs the SQL in the active editor, saved or not, and shows up to 500 rows (write an explicit `limit`). It runs a single statement, so use `union all` to combine checks. Create a scratch file in `analyses/`, run Preview, then revert or delete it before committing.

---

## 3. Decisions (resolved)

- **Real names and data:** the repo is public and the names in tests and descriptions are fictional, so no anonymizing is needed. Credentials live in dbt Cloud, not in the repo, but still check that no service account key was ever committed (PR-01), and parameterize the BigQuery project ID (PR-05).
- **Surrogate keys:** keep readable keys, standardized through a custom `slug_key` macro (PR-07). `STYLE_GUIDE.md` section 5.2 reflects this.
- **dbt version:** the dbt Cloud **v1 Latest** release track, which is past the 1.8 minimum for unit tests. dbt Cloud manages the version through the environment, so the plan doesn't pin `require-dbt-version` (see PR-02).
- **Marts referencing staging:** allowed for pass-throughs only.
- **Currency and timezone:** CAD and `America/Toronto`.
- **Dataset layout:** separate datasets per layer: `staging`, `intermediate`, `marts` (PR-26).
- **Bonuses and extra paychecks:** recorded as category `Paycheck`. No new allocation types (PR-14).
- **Guilt-Free totals:** unspent budget carries over across years, so running totals never reset (PR-16).
- **`dim_cashflow_types` IDs:** stable readable keys through `slug_key` (PR-21).
- **Derived metrics in dimensions:** `dim_savings_goals` and `dim_investments` keep them, as a documented exception (PR-25).
- **Fictional data feed:** a Google Apps Script adds rows to the transactions and investments sheets every day (Task G). Its dates stop at 31 Dec 2026, the end of the 2026 budget.
- **Source freshness:** done after the feed exists (PR-12), with tight thresholds on the sheets the feed writes and long ones on the reference sheets.

---

## 4. The plan

Each block below is one pull request (or one settings task in dbt Cloud): the branch name, the steps, how to verify it, and a **Commit now** line at each point where you should commit, with the message to use. Follow the routine in section 2 for every PR.

> **Caveat:** the SQL and YAML below were written from the files you shared. I haven't run any of it against your warehouse. Build and test each change in your IDE development environment first. Where a snippet depends on a package or a newer dbt feature, check that package's or dbt's docs for your version.

### Phase 0 — Baseline and tooling (no data change)

#### PR-01 · `docs/style-guide`

**Goal:** put the style guide in the repo and make sure the repo has no generated files or credentials. No data changes.

**What it is.** `.gitignore` is a text file telling git which files to never track. dbt generates files you don't want in a repository (compiled SQL, downloaded packages, logs), and credentials must never end up in a repo, especially a public one. With dbt Cloud your warehouse credentials live in dbt Cloud, not in the repo, so the main risk is anything left over from earlier experiments (a downloaded service account key, a `profiles.yml` from dbt Core).

**Steps**

1. In the IDE, create `STYLE_GUIDE.md` in the repo root (right-click the project root in the file tree, choose the new-file option) and paste in the contents.

   **Commit now:** `docs: add project style guide`

2. Open `.gitignore` in the project root (create it if it's missing). It should contain at least:

   ```
   target/
   dbt_packages/
   logs/
   .user.yml
   .env
   *keyfile*.json
   *service-account*.json
   ```

   dbt Cloud needs `target/`, `dbt_packages/` and `logs/` to be ignored, or it can show them as changes. The last three lines are cheap insurance, and they also help anyone who runs the repo with dbt Core.

   **Commit now (only if you changed `.gitignore`):** `chore: update .gitignore`

3. Check that no generated files are already in the repo. On GitHub, open the repository's file list on `main`: there should be no `target`, `dbt_packages` or `logs` folders. If there are, delete them on GitHub (open the folder, use the **...** menu → **Delete directory**) or in the IDE, and commit.

4. Because the repo is public, check the **history** for credentials that were committed and later deleted. You can't run `git log` in the IDE, so use GitHub:
   - Turn on secret scanning, which is free for public repositories but not always enabled by default. Open the repository's **Security and quality** tab (or **Security**) → **Secret scanning**. If it says "Secret scanning is not enabled", click **Enable secret scanning in this repo** and, in the settings page it opens, switch on secret scanning (and push protection, if offered). GitHub then scans the repository's full history, and any detected key is listed under **Secret scanning alerts**. An empty list after the scan finishes means nothing was found.
   - For each name that could have been committed, open `https://github.com/<you>/<repo>/commits/main/<name>` and look for commits. This works even if the file has been deleted. Try `profiles.yml`, `.env` and any `*.json` key file name you remember using.

   No results means the history is clean. If something shows up, **revoke or rotate that credential first** (for a Google service account key, delete the key in Google Cloud). Anything that was public should be treated as compromised, even after you remove it from history.

**PR title:** `docs: add style guide and check repo hygiene`

**PR description** (paste into GitHub):

```markdown
## What changed
Adds `STYLE_GUIDE.md` to the repo root and updates `.gitignore` so `target/`, `dbt_packages/` and `logs/` are ignored.

## Why
The style guide is the reference every later PR is reviewed against. Ignoring generated files keeps them, and any credentials, out of the repo.

## How I verified it
Checked the repo's file list on `main` for generated folders, turned on secret scanning and reviewed its alerts, and looked at the history of `profiles.yml` and `.env`. [Add what you found: nothing, or what you rotated.]

## Does data change?
No. Documentation and repo settings only.
```

#### PR-02 · `chore/dev-tooling`

**Goal:** install the packages and the SQLFluff setup you need for the rest of the plan, and add the helper that compares your dev build with the baseline. No data changes.

**Part 1 · `packages.yml`: pin `dbt_utils`, add `audit_helper` and `dbt_project_evaluator`**

**What it is.** dbt packages are reusable code libraries installed with `dbt deps`. They're listed in `packages.yml` next to `dbt_project.yml`. **Pinning** means giving a version range so `dbt deps` can't silently pull a newer, breaking release.

**What each one does**

| Package | Purpose here |
|---|---|
| `dbt_utils` | You already use its tests (`unique_combination_of_columns`, `accepted_range`, `expression_is_true`). |
| `audit_helper` | Compares two tables row by row. This is how you prove a refactor didn't change any data (see the Baseline step below). |
| `dbt_project_evaluator` | Checks your project against dbt best practices (naming, layering, missing tests and docs). Used for review and in the CI job (PR-29). |

**Steps**

1. Look up the current version of each package on [hub.getdbt.com](https://hub.getdbt.com) and use a range that starts at that version and stops before the next major version. The numbers below are examples only:

   ```yaml
   packages:
     - package: dbt-labs/dbt_utils
       version: [">=1.3.0", "<2.0.0"]
     - package: dbt-labs/audit_helper
       version: [">=0.12.0", "<1.0.0"]
     - package: dbt-labs/dbt_project_evaluator
       version: [">=1.0.0", "<2.0.0"]
   ```

   In the IDE, open `packages.yml` in the project root (create it if it doesn't exist). If `dbt_utils` is already listed, just add the range.

2. Install: type `dbt deps` in the command bar and press Enter. This downloads the packages into `dbt_packages/` (git-ignored) and writes `package-lock.yml`.
3. **Commit `packages.yml` and `package-lock.yml`** (both show up in the IDE's Changes list). The lock file records the exact versions installed, so every run uses the same ones.

   **Commit now:** `chore(config): pin packages`

4. `dbt_project_evaluator` adds its own models and tests to the project, so they'd run in every `dbt build`. For now, run it only when you want to see its findings:

   ```
   dbt build --select package:dbt_project_evaluator
   ```

   and exclude it from normal builds with `--exclude package:dbt_project_evaluator` (every `dbt build` in this plan does). Expect many findings the first time. You'll work through them in PR-29, not now.
5. Jobs in dbt Cloud: add `dbt deps` as the first command of every job. If dbt Cloud already installs packages automatically, the extra command does no harm.

**Part 2 · `.sqlfluff` and `.sqlfluffignore`**

**What it is.** SQLFluff is a linter and formatter for SQL. It reads your SQL, flags style problems (capitalization, indentation, spacing) and can fix most of them automatically. The dbt Cloud IDE has it built in, so there's nothing to install. `.sqlfluff` holds the settings, and `.sqlfluffignore` lists paths it should skip.

**Steps**

1. In the IDE, create `.sqlfluff` in the project root (next to `dbt_project.yml`). If this file exists, the IDE uses SQLFluff rules instead of its default formatter (sqlfmt):

   ```ini
   [sqlfluff]
   dialect = bigquery
   templater = dbt
   runaway_limit = 10
   max_line_length = 120
   indent_unit = space

   [sqlfluff:indentation]
   tab_space_size = 4

   [sqlfluff:rules:capitalisation.keywords]
   capitalisation_policy = lower

   [sqlfluff:rules:capitalisation.functions]
   extended_capitalisation_policy = lower

   [sqlfluff:rules:capitalisation.literals]
   capitalisation_policy = lower

   [sqlfluff:rules:capitalisation.types]
   extended_capitalisation_policy = lower

   [sqlfluff:layout:type:start_bracket]
   spacing_after = single

   [sqlfluff:layout:type:end_bracket]
   spacing_before = single
   ```

   `dialect = bigquery` tells SQLFluff which SQL syntax to expect (your `unpivot`, `safe.parse_date`, backticks). `templater = dbt` lets it understand `{{ ref(...) }}` and your macros by compiling them first (this makes linting a little slower). The capitalisation sections enforce lowercase keywords, as in the style guide. The two `layout` sections enforce a space just inside every bracket, so Fix turns `cast(coalesce(x, 0) as numeric)` into `cast( coalesce( x, 0 ) as numeric )`. This applies to all brackets (`count( * )`, `in ( 1, 2 )`), because SQLFluff can't limit it to function calls. Without these two sections, SQLFluff flags those spaces as `LT01` warnings. To only silence the warning without enforcing the spaces, set both values to `touch:inline`.

2. Create `.sqlfluffignore` in the project root (same syntax as `.gitignore`):

   ```
   target/
   dbt_packages/
   logs/
   snapshots/
   ```

   The IDE doesn't skip these on its own, and snapshots in particular can cause lint errors.

   **Commit now (after you've created both `.sqlfluff` and `.sqlfluffignore`):** `chore: add sqlfluff configuration`

3. Turn on SQLFluff in the IDE. Open a `.sql` file, click the **Code quality** tab in the console (the **`</> Config`** button only appears there, on the right side) and choose **SQLFluff (linting & formatting)**, then **Save**. If you don't see the button, save `.sqlfluff`, commit it, and refresh the browser tab: when `.sqlfluff` exists in the project root, the IDE uses SQLFluff by default.
4. Try it on one file, without changing anything: open `models/staging/google_sheets/stg_google_sheets__accounts.sql` and click **Lint**. Problems appear as wavy underlines in the editor and in the **Code quality** tab. Hover over an underline to see the rule code (like `LT01` or `CP01`), a description and a **Quick Fix**. Linting does not rerun on save: click **Lint** again after edits.
5. If a file shows a templating error although it compiles fine, read the message in the Code quality tab. If you can't resolve it, add that file's path to `.sqlfluffignore` and format it by hand.
6. Some limits to know about: a file that takes more than about 60 seconds to process shows "Unable to complete linting this file" (split the model if that happens), and the IDE doesn't support custom sqlfmt settings. Whether the IDE lints files in `macros/` isn't documented, so you'll test that in PR-03.
7. Don't tune every rule now. After your first lint pass (PR-03), turn off only the rules that clearly fight your style by listing them in `exclude_rules = ...` under `[sqlfluff]`.

**Part 3 · the baseline comparison helper**

In the IDE create `analyses/compare_to_baseline.sql`. It compares one model in your dev dataset with the same model built by the baseline job (the Baseline step below):

```sql
{# Compares one model in your dev dataset with the same model built by the baseline job.
   Edit the four settings below, then click Preview. #}
{% set model_name = 'dim_accounts' %}
{% set primary_key = 'account_id' %}
{% set baseline_schema = 'analytics' %}  {# after PR-26 use 'marts' (or 'intermediate' / 'staging') #}
{% set excluded_columns = [] %}         {# e.g. ['latest_price', 'current_value'] for price- or date-driven columns #}

{{ audit_helper.compare_relations(
    a_relation = ref(model_name),
    b_relation = api.Relation.create(
        database = target.database,
        schema = baseline_schema,
        identifier = model_name
    ),
    exclude_columns = excluded_columns,
    primary_key = primary_key
) }}
```

The result summarizes how many rows match and how many exist in only one table. For a behavior-preserving change, every row should match. Check the `audit_helper` docs for the current macro name and arguments, as they change between versions. If dbt complains that it can't resolve `ref(model_name)`, replace it with a literal such as `ref('dim_accounts')`.

**Comparing every model at once.** Typing a model name and key each time doesn't scale. Create a second file, `analyses/compare_all_to_baseline.sql`, that loops over all your models and compares each one with the baseline in a single **Preview**:

```sql
{# Compares EVERY model in your dev build with the baseline built from main.
   Click Preview. With show_only_differences = true, an empty result means every model matches. #}
{% set show_only_differences = true %}  {# false shows the row counts for every model #}
{% set layered = false %}               {# set to true after PR-26 (each layer in its own dataset) #}
{% set baseline_schema = 'analytics' %} {# used while layered = false #}
{% set skip_models = [] %}              {# e.g. models that don't exist in the baseline yet #}
{% set excluded_columns = {
    'dim_investments': ['latest_price', 'current_value']
} %}                                    {# price- or date-driven columns, per model #}

{% set queries = [] %}
{% if execute %}
    {% for node in graph.nodes.values() | selectattr('resource_type', 'equalto', 'model') | sort(attribute='name') %}
        {% if node.package_name == project_name and node.name not in skip_models %}
            {% set schema = node.fqn[1] if layered else baseline_schema %}
            {% set model_summary %}
                select
                    '{{ node.name }}' as model_name,
                    in_a,
                    in_b,
                    `count`,
                    percent_of_total
                from (
                    {{ audit_helper.compare_relations(
                        a_relation = api.Relation.create(
                            database = node.database,
                            schema = node.schema,
                            identifier = node.alias
                        ),
                        b_relation = api.Relation.create(
                            database = target.database,
                            schema = schema,
                            identifier = node.alias
                        ),
                        exclude_columns = excluded_columns.get(node.name, [])
                    ) }}
                )
            {% endset %}
            {% do queries.append(model_summary) %}
        {% endif %}
    {% endfor %}
{% endif %}

select *
from (
    {{ queries | join('\n    union all\n') }}
)
{% if show_only_differences %}
where not (in_a and in_b)
{% endif %}
order by model_name
```

How to read it: each model produces rows saying how many rows exist in both tables (`in_a` and `in_b` both true), only in your dev build (`in_a` only) or only in the baseline (`in_b` only). With `show_only_differences = true` you only see the mismatches, so an empty result means everything matches. Set it to `false` to see the counts for every model.

- **It needs no `primary_key`.** The package's `primary_key` argument only sorts the unmatched rows, so the loop leaves it out. Use `compare_to_baseline.sql` (one model, with a key) when you need to see *which* rows differ.
- **It reads the tables from your last build.** The dev side is built from each model's dev dataset and name instead of `ref()`, because dbt can't resolve a `ref()` inside a loop (it asks for a `depends_on` hint). So run `dbt build` on your branch before using it, and again after any change.
- **Models are found automatically** from the project, so a new model is included with no edits. Packages (like `dbt_project_evaluator`) are skipped.
- **If a model doesn't exist in the baseline yet** (for example one you just created or renamed in this PR), the whole query fails with a "Not found" error. Add its name to `skip_models`, or run the baseline job first.
- **Price- or date-driven columns:** list them per model in `excluded_columns`, as in the `dim_investments` example. Put in the real column names from the Baseline step.
- Preview shows up to 500 rows, which is plenty for this summary.
- I couldn't run this against your BigQuery project, so test it once on a clean branch. If it reports a Jinja error, the line number in the **Compile** tab points to the cause.

**Commit now:** `chore(analyses): add baseline comparison helper` (after you've created `analyses/compare_to_baseline.sql` and tried it once the baseline exists).

**Left out on purpose:** `require-dbt-version` (dbt Cloud sets the dbt version through the environment's release track, and dbt's docs don't say how the setting behaves on release tracks), pre-commit hooks (the IDE has no local git hooks, so linting runs in the IDE and in the CI job), and a `dev` target (the IDE already is your development environment).
**Note:** don't make lint blocking in CI yet, as nothing is formatted.

**PR title:** `chore: add packages, sqlfluff config and baseline comparison helper`

**PR description** (paste into GitHub):

```markdown
## What changed
Adds `dbt_utils` (pinned range), `audit_helper` and `dbt_project_evaluator` to `packages.yml`, with `package-lock.yml`. Adds `.sqlfluff` and `.sqlfluffignore`. Adds `analyses/compare_to_baseline.sql`, which compares the dev build with the baseline.

## Why
These are the tools the rest of the plan depends on: pinned packages, a lint and format config, and a way to prove refactors don't change data.

## How I verified it
`dbt deps` installs the packages. `dbt build --exclude package:dbt_project_evaluator` passes in the IDE. Lint runs on one staging model and reports style findings.

## Does data change?
No. No model changed.
```

#### Baseline: Production environment and baseline job (dbt Cloud settings, no PR; do this after PR-02 is merged)

**What it is.** A baseline is a copy of what your models produce **today**, before any change. After each refactor you build the changed project in your IDE and compare it to the baseline. If the refactor was truly behavior-preserving, the comparison shows zero differences. In dbt Cloud, the baseline is a **Production environment** whose job builds `main`.

**Steps**

1. **Create the Production environment** (skip if you already have one). In dbt Cloud open **Orchestration → Environments → Create environment**. Choose a **Deployment** environment and set the deployment type to **Production**. This also sets the `DBT_CLOUD_ENVIRONMENT_TYPE` variable to `prod`, which PR-26 uses. Use the same BigQuery connection as development, and set the **dataset** to something different from your development dataset, for example `analytics`. The branch is `main`.
2. **Create the baseline job.** From that environment choose **Create job → Deploy job**. Name it **Baseline: build main**. Commands, in order:

   ```
   dbt deps
   dbt build --exclude package:dbt_project_evaluator
   ```

   Leave the schedule off (you'll run it by hand). Don't tick *Run source freshness*.
3. **Run it once** from clean `main` (**Run now**) and wait for it to finish. Open the run and note any failures or warnings: that's your record of how things stand today. Its output lives in the Production dataset (`analytics`).
4. **Add a totals check for every model.** This is a second, independent check next to `compare_all_to_baseline.sql`: it compares row counts and the sum of every numeric column, for all models in one go. Create `analyses/compare_totals_to_baseline.sql`:

   ```sql
   {# Compares row counts and column sums of EVERY model: your dev build vs the baseline.
      Click Preview. With show_only_differences = true, an empty result means everything matches. #}
   {% set show_only_differences = true %}
   {% set layered = false %}               {# set to true after PR-26 #}
   {% set baseline_schema = 'analytics' %} {# used while layered = false #}
   {% set skip_models = [] %}
   {% set excluded_columns = {
       'dim_investments': ['latest_price', 'current_value']
   } %}
   {% set numeric_types = ['INT64', 'INTEGER', 'FLOAT64', 'FLOAT', 'NUMERIC', 'DECIMAL', 'BIGNUMERIC', 'BIGDECIMAL'] %}

   {% set queries = [] %}
   {% if execute %}
       {% for node in graph.nodes.values() | selectattr('resource_type', 'equalto', 'model') | sort(attribute='name') %}
           {% if node.package_name == project_name and node.name not in skip_models %}
               {% set schema = node.fqn[1] if layered else baseline_schema %}
               {% set dev = api.Relation.create(database=node.database, schema=node.schema, identifier=node.alias) %}
               {% set base = api.Relation.create(database=node.database, schema=schema, identifier=node.alias) %}
               {% set skipped = excluded_columns.get(node.name, []) %}

               {% set row_counts %}
                   select
                       '{{ node.name }}' as model_name,
                       '(row count)' as column_name,
                       cast((select count(*) from {{ dev }}) as float64) as dev_value,
                       cast((select count(*) from {{ base }}) as float64) as baseline_value
               {% endset %}
               {% do queries.append(row_counts) %}

               {% for col in adapter.get_columns_in_relation(dev) %}
                   {% if col.data_type | upper in numeric_types and col.name not in skipped %}
                       {% set column_sum %}
                           select
                               '{{ node.name }}' as model_name,
                               '{{ col.name }}' as column_name,
                               round(cast((select sum({{ col.name }}) from {{ dev }}) as float64), 2) as dev_value,
                               round(cast((select sum({{ col.name }}) from {{ base }}) as float64), 2) as baseline_value
                       {% endset %}
                       {% do queries.append(column_sum) %}
                   {% endif %}
               {% endfor %}
           {% endif %}
       {% endfor %}
   {% endif %}

   select *
   from (
       {{ queries | join('\n    union all\n') }}
   )
   {% if show_only_differences %}
   where dev_value is distinct from baseline_value
   {% endif %}
   order by model_name, column_name
   ```

   An empty result means every model has the same row count and the same column sums as the baseline. If rows appear, `dev_value` and `baseline_value` show the two numbers for that model and column. Set `show_only_differences = false` to see every number. The same notes as for `compare_all_to_baseline.sql` apply: it reads the tables from your last `dbt build` (so build first), a model missing from the baseline makes the query fail (add it to `skip_models`), and price- or date-driven columns go in `excluded_columns`. Sums are rounded to 2 decimals so tiny floating-point differences don't show up as failures.

**Three catches**

- **Build everything in dev with defer off.** In the command bar's **Defer** menu choose **Development**. With defer on, unchanged models are read from Production, so your "dev" side would partly be Production itself.
- **The data moves.** Your sources change when you add sheet rows and when Fivetran syncs, and, once Task G is running (after PR-16), a script adds new rows every day. Production and your dev build can then differ only because one was built before a sync and the other after. Some outputs also depend on today's date or live prices (the XIRR rate, `funding_month`, the retirement projection). So run **Baseline: build main** and then your dev build back-to-back, never across a morning sync; keep the time-dependent columns in `excluded_columns` (from PR-16a: `annualized_return_rate` in `dim_investments`, and `current_value` and `future_value` in `retirement_projection`); and if you need frozen data while checking a fix, pause the generator's trigger (Task G, step 8).
- **Rerun the job after every merge.** `main` is the new baseline once a PR lands.

### Phase 1 — Formatting only (no data change)

#### PR-03 · `style/sqlfluff-format`

**Goal:** apply the style guide's formatting to every SQL and YAML file in one PR, so every later diff stays small. No data changes.

**What it is.** **Lint** only reports style problems. **Fix** edits the file to correct the ones SQLFluff can fix safely (case, spacing, indentation). It doesn't change what the SQL does. In the IDE there is no command to run it over a whole folder: you work file by file, and the IDE's Lint button covers the SQL files you have modified on the current branch.

**Steps** (on the `style/sqlfluff-format` branch, after PR-02)

1. **Create the branch.** Git actions → **Change branch** → `main` → **Pull from remote** if it's offered, then **Create new branch** named `style/sqlfluff-format`.
2. **Check SQLFluff is selected.** **Code quality** tab → **`</> Config`** → SQL linting = **SQLFluff (linting & formatting)** (PR-02, Part 2, step 3). Don't mix it with sqlfmt on the same file: the two disagree on style.
3. **See what a file needs before changing it.** Open one staging model and click **Lint**. Read the **Code quality** tab: you should see mostly capitalisation and spacing issues. This tells you how big the changes will be.
4. **Fix one folder at a time**, so each commit is small enough to review. For each file in `models/staging`:
   1. Open the file and click **Lint**, then **Fix**.
   2. Check the result in the editor, then save the file.
   3. Click **Lint** again. Anything that remains needs a manual fix (for example a very long line) or a rule you decide to exclude.

   When the folder is done, click **Commit and sync** with the message `style(staging): apply sqlfluff formatting`. Repeat for `models/intermediate` (`style(int): ...`) and `models/marts` (`style(marts): ...`).
5. **Try the macros.** Open one file in `macros/` and click **Lint**. Whether the IDE lints macro files isn't documented. If it errors or shows nothing, add `macros/` to `.sqlfluffignore` and keep the macros in the same style by hand (4-space indent, lowercase keywords).
6. **Format the YAML and Markdown.** Open each YAML file and click **Format**: the IDE uses Prettier for YAML, Markdown and JSON, and it normalizes indentation and trailing spaces. Prettier can occasionally re-wrap or re-quote long descriptions, so check the diff. Also add `version: 2` at the top of any of the four YAML files that is missing it. Commit with `style(yaml): normalize indentation and whitespace`.
7. **Review before opening the PR.**
   - In the IDE, the **Changes** list shows every modified file; click one to open the **Git diff view** (before on the left, after on the right).
   - On GitHub, open the PR's **Files changed** tab (it exists only after you click **Create pull request**, not on the "Comparing changes" page) and tick **Hide whitespace** in the diff settings in the toolbar above the file list, next to Split/Unified. If you can't find it, add `?w=1` to the end of the page URL and reload. You should see mostly case changes (`AS` to `as`) and spacing.
8. **Prove nothing changed in meaning.** The IDE can't diff compiled folders, so use the data:
   1. Set **Defer** to **Development** and run `dbt build --exclude package:dbt_project_evaluator`. It must pass.
   2. Run the baseline comparison (see the Baseline step): `analyses/compare_all_to_baseline.sql` and `analyses/compare_totals_to_baseline.sql`; use `analyses/compare_to_baseline.sql` only for models that show differences. Zero differences, apart from the price- and date-driven columns noted in the Baseline step.
   3. For a spot check of the SQL itself, open the **Compile** tab on two or three models and compare with the compiled code from `main` (use **Change branch** to look at `main` if you want to see the old version).
9. **Open the PR** (Git actions → **Open pull request**), using the description template from the routine in section 2.

**PR title:** `style: apply sqlfluff formatting to SQL and YAML`

**PR description** (paste into GitHub):

```markdown
## What changed
Applies SQLFluff Fix to every SQL file (staging, intermediate, marts) and Prettier Format to the YAML files. Adds `version: 2` where it was missing.

## Why
Formatting everything at once, with no logic changes, keeps every later diff small and reviewable.

## How I verified it
`dbt build` passes (Defer = Development). `analyses/compare_to_baseline.sql` shows zero differences for every mart. With whitespace hidden on GitHub, the diff shows only case and spacing changes.

## Does data change?
No.
```

### Phase 2 — Config and documentation (no data change)

#### PR-04 · `docs/fix-descriptions`

**Goal:** accurate, consistent documentation. Nothing in the data changes.

1. **Fix typos.** Find and correct:
   - "Staging mode for single-row table…" → "Staging model for…" (`_stg_google_sheets.yml`, `retirement_assumptions`)
   - "used to investment growth" → "used to project investment growth" (in both `_src_google_sheets.yml` and `_stg_google_sheets.yml`)
   - The `investments_transactions` source description ends with a comma instead of a period
   - "or an  Guilt-Free allowance" (double space, wrong article) → "or a Guilt-Free allowance" (`stg_google_sheets__cashflow_type_category`)
   - The `budget_2026` `type` description has a broken quote: `"Savings, "Investments"` → `"Savings," "Investments"` (in both files)
   - "Staging model for List of savings goals…" → "Staging model for the list of savings goals…"
   - In `_marts.yml`, `retirement_projection` description: "monthly Investments budget amount  to project" (double space)
   - In `_marts.yml`, the descriptions of `fct_budget_vs_actual` and `fct_budget_vs_actual_fixed_costs` both contain "Variance Amount is signed so that…". Change "Variance Amount" to `variance_amount` in both (search for `Variance Amount`: two hits). Don't change the column names, which are already correct.

   Useful searches (Cmd/Ctrl+P → **Search for Text**): `Staging mode`, `used to investment`, and two spaces in a row (`  Guilt`, `amount  to`).
2. **Fix copy-paste descriptions:**
   - `int_cashflow_transactions_agg_month.transaction_month`: "Date the transaction occurred." → "First day of the calendar month in which the transactions occurred."
   - `budget_amount` in `int_budget_2026_fixed_costs_unpivoted` should say "for this `budget_item`"; in `int_budget_2026_fixed_costs_agg_category` and `int_budget_fixed_costs` it should say "for this `budget_category`" (they all say `budget_type` today)

   **Commit now (after steps 1 and 2):** `docs: fix typos and copy-paste errors in model descriptions`

3. **Document `int_accounts`.** Add to `_int.yml` (same `arguments:` syntax as your other tests):
   ```yaml
     - name: int_accounts
       description: >
         One row per account. Combines each account's beginning balance with the sum of all its cashflow
         transactions to calculate the current balance in dbt. This calculated balance can be compared with
         the balance the sheet calculates itself (`current_balance_sheet` in staging).
       columns:
         - name: account_id
           description: Unique identifier for the account.
           data_tests: [unique, not_null]
         - name: account_name
           description: Account name, including the type and holder (e.g. Chequing Kenji).
           data_tests: [unique, not_null]
         - name: account_type
           description: High-level classification of the account, Assets or Liabilities.
           data_tests:
             - not_null
         - name: account_category
           description: Functional grouping of the account (e.g. Chequing, Savings).
           data_tests:
             - not_null
         - name: beginning_balance
           description: Balance recorded when the account was first added to the file.
           data_tests:
             - not_null
         - name: current_balance
           description: beginning_balance plus the sum of all transaction amounts for the account. Accounts with no transactions equal their beginning balance.
           data_tests:
             - not_null
   ```

   **Commit now:** `docs(int): document int_accounts`

4. **Add a grain sentence** ("One row per …") to the start of every model description. Use this table:

   | Model | Grain |
   |---|---|
   | `stg_..._accounts` | one row per account |
   | `stg_..._budget_2026` | one row per budget type (wide: one column per month) |
   | `stg_..._budget_2026_fixed_costs` | one row per fixed-cost line item (wide) |
   | `stg_..._cashflow_transactions` | one row per transaction |
   | `stg_..._cashflow_type_category` | one row per type/category pair |
   | `stg_..._investments_prices` | one row per ticker |
   | `stg_..._investments_transactions` | one row per investment transaction |
   | `stg_..._retirement_assumptions` | a single row |
   | `stg_..._savings_goals` | one row per goal |
   | `stg_..._savings_goals_details` | one row per goal line item |
   | `int_accounts` | one row per account |
   | `int_budget_2026_unpivoted`, `int_budget` | one row per budget type per month |
   | `int_budget_latest_month` | one row per budget type, for the latest month only |
   | `int_budget_2026_fixed_costs_unpivoted` | one row per budget item per month |
   | `int_budget_2026_fixed_costs_agg_category`, `int_budget_fixed_costs` | one row per fixed-cost category per month |
   | `int_cashflow_transactions_agg_month` | one row per type, category and month |
   | `int_investments_current_position` | one row per ticker |
   | `dim_accounts` | one row per account |
   | `dim_cashflow_categories` | one row per type/category pair |
   | `dim_cashflow_types` | one row per cashflow type |
   | `dim_dates` | one row per calendar day |
   | `dim_investments` | one row per ticker |
   | `dim_savings_goals` | one row per active goal |
   | `fct_budget` | one row per budget type per month |
   | `fct_budget_fixed_costs` | one row per fixed-cost category per month |
   | `fct_budget_vs_actual` | one row per budget type per month |
   | `fct_budget_vs_actual_fixed_costs` | one row per fixed-cost category per month |
   | `fct_budget_vs_actual_guilt_free` | one row per Guilt-Free budget type per month |
   | `fct_cashflow_transactions` | one row per transaction |
   | `fct_investments_transactions` | one row per investment transaction |
   | `fct_monthly_paycheck_allocation` | one row per allocation type per month |
   | `retirement_projection` | a single row |

   **Commit now:** `docs: add grain statement to every model description`

5. **Create doc blocks** for descriptions that are *identical* in three or more places. Don't force one text onto columns that really differ: where a description is specific to one model, keep it inline in the YAML. For example, `budget_amount` is four different descriptions and `budget_type` is three:

   | Column | Use | Models |
   |---|---|---|
   | `budget_amount` | doc block `budget_amount_by_type`: "The budgeted dollar amount for this `budget_type` in this `budget_month`." | `int_budget_2026_unpivoted`, `int_budget`, `int_budget_latest_month`, `fct_budget`, `fct_budget_vs_actual`, `fct_budget_vs_actual_guilt_free` |
   | `budget_amount` | doc block `budget_amount_by_category`: "The budgeted dollar amount for this `budget_category` in this `budget_month`." | `int_budget_2026_fixed_costs_agg_category`, `int_budget_fixed_costs`, `fct_budget_fixed_costs`, `fct_budget_vs_actual_fixed_costs` |
   | `budget_amount` | inline: "...for this `budget_item` in this `budget_month`." | `int_budget_2026_fixed_costs_unpivoted` |
   | `budget_amount` | inline, keep as is | `fct_monthly_paycheck_allocation` |
   | `budget_type` | doc block `budget_type`: "The budget category, e.g. Savings, Investments, Fixed Costs, Income, or one of the individual Guilt-Free categories." | `int_budget_2026_unpivoted`, `int_budget`, `int_budget_latest_month`, `fct_budget`, `fct_budget_vs_actual` |
   | `budget_type` | inline, keep | `fct_budget_vs_actual_guilt_free` ("The Guilt-Free budget type.") and `stg_google_sheets__budget_2026` (it describes the raw labels, including the subtotal row) |

   The same approach applies to the other repeated columns (`budget_month_id`, `budget_month`, `_loaded_at`, `transaction_type`). Put the blocks in `models/docs.md`:
   ```
   {% docs budget_amount_by_type %}
   The budgeted dollar amount for this `budget_type` in this `budget_month`.
   {% enddocs %}
   ```
   and reference them in YAML (the quotes are required):
   ```yaml
   - name: budget_amount
     description: "{{ doc('budget_amount_by_type') }}"
   ```
   To share a text but add something for one model, combine them: `description: "{{ doc('budget_type') }} In this model only Guilt-Free types appear."`

   **Commit now:** `docs: add doc blocks for repeated columns`

6. **Verify:** run `dbt parse` (YAML is valid), `dbt docs generate` (available in the command bar on dbt v1) and `dbt build`; all must pass. Spot-check a few descriptions in the IDE and, after the next baseline run, in dbt Cloud's catalog. No data comparison needed.

**PR title:** `docs: fix descriptions, document int_accounts and add doc blocks`

**PR description** (paste into GitHub):

```markdown
## What changed
Fixes typos and copy-paste descriptions in the YAML, documents `int_accounts` in `_int.yml` (with tests), adds a grain sentence to every model description, and moves repeated column descriptions into doc blocks in `models/docs.md`.

## Why
Accurate, consistent documentation is part of the style guide, and `int_accounts` had no description or tests.

## How I verified it
`dbt parse` and `dbt build` pass, `dbt docs generate` runs, and I spot-checked the descriptions in the IDE.

## Does data change?
No. Only descriptions and tests on `int_accounts` changed.
```

#### PR-05 · `chore/project-config`

**Goal:** tidy `dbt_project.yml` and parameterize hardcoded values. No data change.

1. **Remove the template comments** from `dbt_project.yml` (the paragraphs about "the example folder" and default views). Keep short comments that describe *your* choices.

   **Commit now:** `chore(config): remove template comments`

2. **Leave the connection settings in dbt Cloud.** dbt Cloud ignores the `profile:` line and uses the connection configured on the project and its environments, so nothing needs changing there. If you want the repo to work for people who run it with dbt Core, rename `profile: 'default'` to `profile: 'personal_finances'` and mention that profile name in the README (PR-30).
3. **Persist documentation to BigQuery** so descriptions show up on the tables and columns:
   ```yaml
   models:
     personal_finances:
       +persist_docs:
         relation: true
         columns: true
   ```
   After `dbt build`, check a table's description in the BigQuery console.

   **Commit now:** `chore(config): persist docs to BigQuery`

4. **Add the timezone variable and `today()` macro** (not used yet):
   ```yaml
   vars:
     project_timezone: 'America/Toronto'
   ```
   `macros/today.sql`:
   ```sql
   {% macro today() %}
       current_date('{{ var("project_timezone") }}')
   {% endmacro %}
   ```

   **Commit now:** `chore(config): add timezone variable and today() macro`

5. **Parameterize the source database.** In `_src_google_sheets.yml`, replace the hardcoded project ID:
   ```yaml
   database: "{{ var('source_database', target.database) }}"
   ```
   If your raw data lives in the same project as your models (likely), nothing else is needed, as `target.database` is the BigQuery project.

   **Commit now:** `chore(config): parameterize source database`

6. **Verify:** open `stg_google_sheets__accounts.sql` and check on the **Compile** tab that the compiled SQL still contains your project ID. Then run `dbt build` plus the baseline comparison (persisting docs only changes metadata).

**PR title:** `chore(config): tidy dbt_project.yml, add timezone var and today() macro`

**PR description** (paste into GitHub):

```markdown
## What changed
Removes the `dbt init` template comments from `dbt_project.yml`, adds `+persist_docs`, adds the `project_timezone` var and a `today()` macro (not used yet), and parameterizes the source `database:`.

## Why
Descriptions should show up in BigQuery, the timezone must live in one place, and the source project ID shouldn't be hardcoded in a public repo.

## How I verified it
`dbt build` passes. The Compile tab for a staging model still contains the project ID. Table descriptions appear in BigQuery.

## Does data change?
No. Only table and column metadata.
```

### Phase 3 — Behavior-preserving refactors (verify: 0 differences)

Each PR follows the same pattern: add the macro, replace all call sites, then verify.

Every PR here must show **zero differences** in the baseline comparison (step 5 of the routine in section 2). If one doesn't, the refactor changed behavior: find out why before merging.

A fast extra check for macro refactors: open the **Compile** tab for one or two affected models before and after the change and compare the SQL (there is no folder diff in the IDE).

#### PR-06 · `refactor/parse-sheet-date-macro`

1. Create `macros/parse_sheet_date.sql`:
   ```sql
   {% macro parse_sheet_date(column_name) %}
       safe.parse_date('%d/%b/%Y', {{ column_name }})
   {% endmacro %}
   ```

   **Commit now:** `refactor(macros): add parse_sheet_date`

2. Replace the four inline calls:
   - `stg_google_sheets__cashflow_transactions`: `{{ parse_sheet_date('date') }} as transaction_date`
   - `stg_google_sheets__investments_transactions`: `{{ parse_sheet_date('date') }} as event_date`
   - `stg_google_sheets__savings_goals`: the two calls for `initial_target_date` and `actual_date`

   **Commit now:** `refactor(staging): use parse_sheet_date`

3. Search to make sure none are left: Cmd/Ctrl+P → **Search for Text** → `parse_date`, and check that the only hit in `models/staging` is the macro call.
4. **Verify:** the **Compile** tab shows the same SQL as before (apart from whitespace) for one model; the baseline comparison is clean.

**PR title:** `refactor(macros): add parse_sheet_date macro for staging dates`

**PR description** (paste into GitHub):

```markdown
## What changed
Adds the `parse_sheet_date` macro and uses it at the four places staging models parse sheet dates.

## Why
The same `safe.parse_date('%d/%b/%Y', ...)` expression was repeated. One macro keeps the format in one place.

## How I verified it
`dbt build` passes, the Compile tab shows the same SQL as before for one model, and `compare_to_baseline.sql` shows zero differences for the affected marts.

## Does data change?
No.
```

#### PR-07 · `refactor/key-macro`

1. **Before writing the macro, check the hyphen risk.** Some keys strip hyphens and spaces, others only spaces. Create a scratch file in `analyses/`, paste this single query and click **Preview**. It should return no rows (revert the file afterward):
   ```sql
   select 'budget_item' as column_name, budget_item as value
   from {{ ref('stg_google_sheets__budget_2026_fixed_costs') }}
   where budget_item like '%-%'
   union distinct
   select 'budget_category', budget_category
   from {{ ref('stg_google_sheets__budget_2026_fixed_costs') }}
   where budget_category like '%-%'
   union distinct
   select 'transaction_category', transaction_category
   from {{ ref('stg_google_sheets__cashflow_transactions') }}
   where transaction_category like '%-%'
   ```
   If any rows come back, the single macro would change those keys. Either add a `strip_hyphens` argument to the macro that matches today's behavior, or accept the change and record it in the PR.
2. Create `macros/slug_key.sql`. Text parts are slugified; the date part is kept as ISO text (**it must not be slugified**, or `2026-01-01` would become `20260101`):
   ```sql
   {% macro slug_key(text_columns, date_column=none) %}
       {%- set pieces = [] -%}
       {%- for col in text_columns -%}
           {%- do pieces.append("lower(replace(replace(" ~ col ~ ", '-', ''), ' ', ''))") -%}
       {%- endfor -%}
       {%- if date_column -%}
           {%- do pieces.append("cast(" ~ date_column ~ " as string)") -%}
       {%- endif -%}
       {{ pieces | join(" || '_' || ") }}
   {% endmacro %}
   ```

   **Commit now:** `refactor(macros): add slug_key`

3. Replace the four hand-built keys:
   | Model | Replacement |
   |---|---|
   | `int_budget_2026_unpivoted` | `{{ slug_key(['budget_type'], 'budget_month') }} as budget_month_id` |
   | `int_budget_2026_fixed_costs_unpivoted` | `{{ slug_key(['budget_item'], 'budget_month') }} as budget_fixed_costs_item_id` |
   | `int_budget_2026_fixed_costs_agg_category` | `{{ slug_key(['budget_category'], 'budget_month') }} as budget_fixed_costs_month_id` |
   | `int_cashflow_transactions_agg_month` | `{{ slug_key(['transaction_type', 'transaction_category'], 'transaction_month') }} as transaction_month_id` |

   **Commit now:** `refactor(int): use slug_key for surrogate keys`

4. **Verify:** run `analyses/compare_to_baseline.sql` for each model, using the key column as `primary_key`. If any key value changed, the comparison reports rows present in only one side. Expected result: none.

**PR title:** `refactor(macros): standardize surrogate keys with slug_key`

**PR description** (paste into GitHub):

```markdown
## What changed
Adds the `slug_key` macro and replaces the four hand-built surrogate key expressions in the intermediate models.

## Why
The keys were built in several slightly different ways. One macro keeps the readable key format consistent.

## How I verified it
Checked that no `budget_item`, `budget_category` or `transaction_category` value contains a hyphen. `compare_to_baseline.sql` on the four models, with the key column as `primary_key`, shows no rows present on only one side.

## Does data change?
No. Key values are identical.
```

#### PR-08 · `refactor/unpivot-budget-macro`

1. Create `macros/unpivot_budget_months.sql`:
   ```sql
   {% macro unpivot_budget_months(relation, year, id_columns) %}
       {%- set months = ['january','february','march','april','may','june',
                         'july','august','september','october','november','december'] -%}
       select
           {{ id_columns | join(', ') }},
           parse_date('%B %Y', replace(month_column, '_', ' ')) as budget_month,
           cast(amount as numeric) as budget_amount
       from {{ relation }}
       unpivot(
           amount for month_column in (
               {%- for m in months %}
               {{ m }}_{{ year }}{{ "," if not loop.last }}
               {%- endfor %}
           )
       )
   {% endmacro %}
   ```

   **Commit now:** `refactor(macros): add unpivot_budget_months`

2. Use it in `int_budget_2026_unpivoted` (keeping the later key and exclusion steps):
   ```sql
   with unpivoted as (
       {{ unpivot_budget_months(ref('stg_google_sheets__budget_2026'), 2026, ['budget_type']) }}
   ),
   ...
   ```
   and in `int_budget_2026_fixed_costs_unpivoted` with `['budget_category', 'budget_item']`. Keep the `where ... is not null` filters in this step, so the commit only swaps the SQL for the macro call. Step 4 decides whether they can go.

   **Watch out:** if you keep the `budget` import CTE and call the macro with its name, put the name in quotes: `{{ unpivot_budget_months('budget', 2026, ['budget_category', 'budget_item']) }}`. Without quotes, Jinja treats `budget` as an undefined variable and prints nothing, so the compiled SQL says `from unpivot(…)` and BigQuery fails with `Expected ")" but got keyword FOR`. Passing `ref('...')` directly (as above) has no such problem. Check the **Compile** tab: the `from` line should name the table.

   **Commit now:** `refactor(int): use unpivot macro for 2026 budgets`

3. **Move the empty-row filter for the fixed-costs budget into staging.** In `stg_google_sheets__budget_2026_fixed_costs`, add the same pattern `stg_google_sheets__budget_2026` uses: drop rows where `category`, `item` and all twelve month columns are null.

   **Commit now:** `refactor(staging): filter empty rows in fixed costs budget`

4. **Decide whether the `where ... is not null` filters can go.** Both unpivoted models have one (`where budget_type is not null` and `where budget_category is not null`). Their job was to drop the empty rows of the sheet. Now that both staging models drop fully empty rows, the filters only matter for a row that has a month value but no key, and those would be dropped silently. Check whether that ever happens, with a scratch file in `analyses/`:

   ```sql
   select 'budget_2026' as model, count(*) as rows_without_key
   from {{ ref('stg_google_sheets__budget_2026') }}
   where budget_type is null
   union all
   select 'budget_2026_fixed_costs', count(*)
   from {{ ref('stg_google_sheets__budget_2026_fixed_costs') }}
   where budget_category is null
   ```

   - **Both 0:** the filters never remove anything, so delete both `where ... is not null` lines. Make sure `budget_type` and `budget_category` have a `not_null` test in the staging YAML, so a future blank key fails loudly instead of disappearing.
   - **Not 0:** those rows currently vanish without a warning. Look at them in the sheet. If they are real mistakes, fix the sheet and delete the filters. If they're intentional (for example a totals row), keep the filter and add a comment saying what it removes.

   **Commit now (only if you deleted the filters):** `refactor(int): remove redundant null-key filters from unpivoted budgets`

5. **Verify:** compare both unpivoted models against the baseline (same row count and values).

**PR title:** `refactor(macros): add unpivot_budget_months macro`

**PR description** (paste into GitHub):

```markdown
## What changed
Adds the `unpivot_budget_months` macro, uses it in both yearly unpivot models, and moves the empty-row filter for the fixed-costs budget into staging.

## Why
Adding a new budget year becomes one macro call, and both budgets now drop empty rows in the same layer.

## How I verified it
`dbt build` passes. `compare_to_baseline.sql` on both unpivoted models and `int_budget` / `int_budget_fixed_costs` shows zero differences.

## Does data change?
No.
```

#### PR-09 · `refactor/staging-consistency`

1. **Explicit casts.** Every column that leaves a staging model gets an explicit type. Fivetran picks column types from whatever it sees in each sheet, so if someone types text into a number column the type can change silently; an explicit `cast` makes that fail loudly in the build and documents the type you expect. First look up the current type of each source column so every new cast is a no-op for now:
   ```sql
   select table_name, column_name, data_type
   from `personal-finances-501019.src_google_sheets.INFORMATION_SCHEMA.COLUMNS`
   order by table_name, ordinal_position
   ```
   Then apply these rules:
   - **A column with no cast:** cast it to the type it has in the source, in lowercase: `cast( goal_priority as int64 )`, `cast( account as string ) as account_name`, `cast( quantity as float64 )`, `cast( latest_trade_time as datetime )`, `cast( _fivetran_synced as timestamp ) as _loaded_at`. Text columns get a cast too.
   - **A column that already has a cast:** leave it, even if it differs from the source type. If you already cast a `float64` source column to `numeric`, the model outputs `numeric` today, and changing it back would change the output type, which this PR must not do. Your budget month columns and the balances in `stg_google_sheets__accounts` are examples.
   - **Dates you already parse** with `parse_sheet_date` are typed already. Keep `datetime` and `timestamp` as they are: converting between them can shift values.
   - **`numeric` is for money.** `float64` is a binary floating-point type, so sums can be slightly off, which matters for the reconciliation tests. A rule of thumb: currency amounts `numeric`, counts and ids `int64`, rates and ratios `float64`, share quantities `numeric` if fractional shares matter (otherwise `float64` is fine).
   - **If a column holding amounts still passes through as `float64`,** changing it to `numeric` is a real type change that can alter values slightly. Do it in its own PR, with the baseline comparison to show what moved. Type changes (if you want any) don't belong in this one.

   **Commit now:** `refactor(staging): cast all columns explicitly`

2. **Name the last CTE `final`** in every model. Find the current last CTEs with Cmd/Ctrl+P → **Search for Text** → `select * from` (the final `select * from <cte>` line in each model), then rename the CTE (`cleaned_columns`, `selected_columns`, `added_key`, `current_position`, `added_annualized_return_to_current_position`, …) and the final select.

   **Style decision.** `final` is a convention, not a correctness rule: one name for the last CTE tells a reader where the output is and keeps diffs stable when logic is added, while a descriptive name (such as `cleaned_columns`) says what the model does. dbt Labs' own guides are split. The plan applies `final` everywhere. If you'd rather keep the descriptive name in staging (it avoids renaming ten models for little benefit) and use `final` only in intermediate and marts, do that, skip the staging models in this step, and say so in `STYLE_GUIDE.md` and the PR description.

   **Commit now:** `refactor: rename final CTEs consistently`

3. **Add `_loaded_at` to `stg_google_sheets__retirement_assumptions`:** `_fivetran_synced as _loaded_at`. Add the column to its YAML entry with a description and a `not_null` test, as in the other staging models.

   **Commit now:** `refactor(staging): add _loaded_at to retirement_assumptions`

4. **Verify:** baseline comparison on all marts (staging changes should be invisible there).

**PR title:** `refactor(staging): cast all columns explicitly and standardize final CTEs`

**PR description** (paste into GitHub):

```markdown
## What changed
Adds an explicit `cast` to every staging column (to the type it already has), renames the last CTE to `final` in every model, and adds `_loaded_at` to `stg_google_sheets__retirement_assumptions`.

## Why
Style guide: explicit types in staging, one name for the last CTE, and `_loaded_at` on every staging model.

## How I verified it
Looked up the existing column types in `INFORMATION_SCHEMA` so each cast changes nothing. `dbt build` passes and every mart matches the baseline.

## Does data change?
No. One new column, `_loaded_at`, on a staging model.
```

#### PR-10 · `refactor/shared-business-rules`

1. **Create the shared rules** in `macros/budget_rules.sql`:
   ```sql
   {% macro is_inflow_type(column_name) %}
       {{ column_name }} in ('Income', 'Paycheck', 'Investments', 'Savings')
   {% endmacro %}

   {% macro is_guilt_free(column_name) %}
       {{ column_name }} like 'Guilt-Free%'
   {% endmacro %}

   {% macro signed_variance(type_column, budget_column, actual_column) %}
       case
           when {{ is_inflow_type(type_column) }} then {{ actual_column }} - {{ budget_column }}
           else {{ budget_column }} - {{ actual_column }}
       end
   {% endmacro %}
   ```
   (`Paycheck` is included so the same macro serves the allocation model, where `Income` is renamed.)

   **Commit now:** `refactor(macros): add shared budget type rules`

2. **Replace the duplicates:**
   - `fct_budget_vs_actual`: the variance `case` becomes `{{ signed_variance('budget_type', 'budget.budget_amount', 'coalesce(actual.actual_amount, 0)') }}`
   - `fct_monthly_paycheck_allocation`: the variance `case` and both `like 'Guilt-Free%'` checks
   - `fct_budget_vs_actual_guilt_free`: the `like 'Guilt-Free%'` filter

   **Commit now:** `refactor(marts): use shared rules in budget facts`

3. **Check the `'Budget'` row before removing its filters.** In the IDE (Preview in a scratch file) or the BigQuery console: `select distinct type from src_google_sheets.budget_2026`, and run `dbt test --select source:google_sheets.budget_2026`. Note that `Budget` isn't in the source's `accepted_values` list.
   - If the row **doesn't exist**, delete the `'Budget'` exclusions and their comment.
   - If it **does exist**, the source test is failing today. Add `'Budget'` to the accepted values so the filter is documented, and keep the filter.
   - Either way, the **marts** filters are dead code, because `int_budget` already excludes both values: remove `where budget.budget_type <> 'Budget'` in `fct_budget_vs_actual`, and the two `<>` filters in `fct_monthly_paycheck_allocation`. The `'Guilt-Free Total'` exclusion in `int_budget_2026_unpivoted` is live (the row exists in the source), so keep it.

   **Commit now (once the check shows the filters are redundant):** `refactor: remove redundant budget filters`

4. **Verify:** baseline comparison on `fct_budget_vs_actual`, `fct_budget_vs_actual_guilt_free` and `fct_monthly_paycheck_allocation`: zero differences.

**PR title:** `refactor(macros): share budget type rules across budget facts`

**PR description** (paste into GitHub):

```markdown
## What changed
Adds the `is_inflow_type`, `is_guilt_free` and `signed_variance` macros and uses them in the budget-vs-actual facts and the paycheck allocation model. Removes the redundant `'Budget'` and `'Guilt-Free Total'` filters in the marts.

## Why
The same rules were copied across four models, and dead filters made the data flow harder to follow.

## How I verified it
Checked the source for a `Budget` row. [Add the result.] `compare_to_baseline.sql` on the three budget-vs-actual facts and `fct_monthly_paycheck_allocation` shows zero differences.

## Does data change?
No.
```

**Checkpoint (end of phase 3):** run the baseline job and compare **every** mart. Zero differences, apart from the date- and price-dependent columns noted in the Baseline step.

### Phase 4 — Safety-net tests (additive)

New tests start as `severity: warn`. A failure here is a **finding about your data or models**, not a reason to block the PR. Phase 5 fixes the findings, then promotes these tests to errors.

#### PR-11 · `test/relationships`

A `relationships` test checks that every value in a column exists in a column of another model (a foreign key check).

1. Add the tests. In your `arguments:` style:
   ```yaml
   - name: account_name
     data_tests:
       - not_null
       - relationships:
           arguments:
             to: ref('dim_accounts')
             field: account_name
           config:
             severity: warn
   ```
   (Older dbt versions put `to` and `field` directly under `relationships:`.) Add them to:

   | Column | References |
   |---|---|
   | `fct_cashflow_transactions.account_name` | `dim_accounts.account_name` |
   | `fct_cashflow_transactions.transaction_type` | `dim_cashflow_types.cashflow_type` |
   | `fct_investments_transactions.account_name` | `dim_accounts.account_name` |
   | `fct_investments_transactions.ticker` | `dim_investments.ticker` |
   | `fct_budget.budget_type` (and the other budget facts) | `dim_cashflow_types.cashflow_type` |
   | `fct_budget.budget_month` (and the other budget facts) | `dim_dates.calendar_date` |

2. The `(type, category)` pair needs a singular test, since `relationships` checks one column. `tests/assert_transaction_categories_exist.sql`:
   ```sql
   {{ config(severity='warn') }}

   select t.transaction_type, t.transaction_category
   from {{ ref('fct_cashflow_transactions') }} as t
   left join {{ ref('dim_cashflow_categories') }} as c
       on c.cashflow_type = t.transaction_type
       and c.cashflow_category = t.transaction_category
   where c.cashflow_category is null
   group by 1, 2
   ```

   **Commit now (after steps 1 and 2):** `test(tests): add relationships tests`

3. Run `dbt test --select test_type:generic` and read the failures. A failure here is information: for example, whether `Savings Spending` (valid in `cashflow_type_category`, absent from the transaction tests) is really used.
4. **Replace the duplicated `accepted_values` lists.** Sources and staging are where the value lists originate, so leave them as they are in this PR. Everywhere else the rule is the same:
   - If a list is **identical** to the one upstream, delete it: the upstream test already guards those values.
   - If it **differs** because the model filters rows or creates the values itself, keep it: it checks something new.
   - On the fact tables, where step 1 added a `relationships` test for the same column, delete the list as well: the relationship test does that job.

   (A `relationships` test goes only on the fact tables, pointing at a dimension. Don't add one from an intermediate model back to staging.) Based on your YAML:

   | Model.column | Action | Why |
   |---|---|---|
   | `int_budget_2026_unpivoted.budget_type` | **Keep** | Its list has no `Guilt-Free Total`, because the model filters it out |
   | `int_budget.budget_type`, `int_budget_latest_month.budget_type` | Delete | Same list as the model above |
   | `int_budget_2026_fixed_costs_unpivoted`, `int_budget_2026_fixed_costs_agg_category`, `int_budget_fixed_costs` (`budget_category`) | Delete | Same as staging |
   | `int_cashflow_transactions_agg_month.transaction_type` | Delete | Same as staging |
   | `int_investments_current_position.investment_type` | Delete | Same as staging |
   | `dim_accounts.account_type` and `account_category` | Delete | Pass-through from staging |
   | `dim_cashflow_categories.cashflow_type`, `dim_cashflow_types.cashflow_type` | Delete | Same list as `stg_google_sheets__cashflow_type_category` |
   | `dim_dates.calendar_quarter` | **Keep** | The model creates these values |
   | `dim_savings_goals.goal_status` and `goal_status_id` | **Keep** | The model creates these values |
   | `fct_budget.budget_type`, `fct_budget_vs_actual.budget_type` | Delete | Replaced by the `relationships` test to `dim_cashflow_types` |
   | `fct_budget_vs_actual_guilt_free.budget_type` | **Keep** | Only four Guilt-Free values, so it checks the model's filter |
   | `fct_budget_fixed_costs.budget_category` | Delete | Same as staging |
   | `fct_budget_vs_actual_fixed_costs.budget_category` | **Keep** | PR-17 relies on it to flag an unbudgeted or misspelled category after the `full outer join` |
   | `fct_cashflow_transactions.transaction_type` | Delete | Replaced by the `relationships` test |
   | `fct_investments_transactions.investment_type` and `investment_event` | Delete | Same as staging |
   | `fct_monthly_paycheck_allocation.allocation_type` | **Keep** | The model creates these values (`Paycheck`, `Guilt-Free`, ...) |

   How to do it: delete only the `- accepted_values:` block (with its `arguments:` and `values:`) from each "Delete" row and leave `not_null` and the other tests on the column. Run `dbt test`. If one of the new `relationships` tests still fails, keep the old list for that column until it's fixed.

   **Commit now:** `test(tests): replace duplicated accepted_values`

**PR title:** `test: add relationships tests and replace duplicated accepted_values`

**PR description** (paste into GitHub):

```markdown
## What changed
Adds `relationships` tests from the facts to the dimensions (all `severity: warn`), a singular test for type/category pairs, and replaces duplicated `accepted_values` lists with `relationships` to the reference table.

## Why
Nothing checked that facts point at real accounts, types or categories, and the value lists had drifted (`Savings Spending`).

## How I verified it
`dbt test` runs. Failures: [list them, or say none]. Any failure is a finding for Phase 5.

## Does data change?
No. Tests only.
```

#### PR-12 · `test/source-freshness` (moved)

Moved to the **Interlude** after PR-16. Freshness only means something once data arrives regularly, so it comes after the data feed (Task G).

#### PR-13 · `test/reconciliation`

Singular tests live in `tests/` as a `select` that returns the **bad rows**: zero rows means pass. Start each with `{{ config(severity='warn') }}`.

1. `tests/assert_fixed_costs_budget_matches_categories.sql`:
   ```sql
   with by_category as (
       select budget_month, sum(budget_amount) as category_total
       from {{ ref('fct_budget_fixed_costs') }}
       group by 1
   ),
   by_type as (
       select budget_month, budget_amount as type_total
       from {{ ref('fct_budget') }}
       where budget_type = 'Fixed Costs'
   )
   select *
   from by_type
   full outer join by_category using (budget_month)
   where abs(coalesce(type_total, 0) - coalesce(category_total, 0)) > 0.01
   ```

   **Commit now:** `test(tests): reconcile fixed costs budget to category sum`

2. `tests/assert_fixed_costs_actuals_match_categories.sql`: the same shape, comparing `actual_amount` in `fct_budget_vs_actual` (`budget_type = 'Fixed Costs'`) with the sum of `actual_amount` in `fct_budget_vs_actual_fixed_costs`. **This is expected to fail today** (unbudgeted categories are dropped); PR-17 fixes it.

   **Commit now:** `test(tests): reconcile fixed costs actuals to category sum`

3. `tests/assert_account_balances_match_sheet.sql`:
   ```sql
   select a.account_name, a.current_balance, s.current_balance_sheet
   from {{ ref('int_accounts') }} as a
   inner join {{ ref('stg_google_sheets__accounts') }} as s using (account_name)
   where abs(a.current_balance - s.current_balance_sheet) > 0.01
   ```

   **Commit now:** `test(tests): reconcile account balances to sheet balances`

4. `tests/assert_guilt_free_variance_is_zero.sql`:
   ```sql
   select *
   from {{ ref('fct_monthly_paycheck_allocation') }}
   where allocation_type = 'Guilt-Free' and allocation_variance <> 0
   ```
   (Expected to fail today; PR-14 fixes it.)

   **Commit now:** `test(tests): assert guilt-free variance is zero`

5. `tests/assert_retirement_projection_single_row.sql`:
   ```sql
   select count(*) as row_count
   from {{ ref('retirement_projection') }}
   having count(*) <> 1
   ```

   **Commit now:** `test(tests): assert retirement projection has one row`

6. In `_int.yml`, add a `unique` test on `ticker` for `int_investments_current_position`.

   **Commit now:** `test(marts): assert unique ticker in int_investments_current_position`

7. Run `dbt test` and keep a note of which ones fail. Those are your Phase 5 targets.

(The full paycheck-allocation reconciliation is written in PR-14, after the `Unallocated` row exists.)

**PR title:** `test: add reconciliation tests for budgets, balances and projections`

**PR description** (paste into GitHub):

```markdown
## What changed
Adds singular tests in `tests/`: fixed-cost totals, account balance vs sheet balance, Guilt-Free variance, a single-row `retirement_projection`, and a unique `ticker` test. All start as `severity: warn`.

## Why
These protect the numbers that matter. Some are expected to fail today, and each failure points to a fix in Phase 5.

## How I verified it
Ran `dbt test`. Failing tests: [list]. Expected failures: Guilt-Free variance and fixed-cost actuals.

## Does data change?
No. Tests only.
```

### Phase 5 — Correctness fixes (data changes on purpose, test-first)

Pattern for each PR: prove the bug first with a failing test (a test you add in the PR, or one from PR-13 that already fails), then fix it. Where a failing test isn't possible, the PR says why. Commit the test before the fix when the test is new, as the **Commit now** lines show. **The PR description must list the data changes you expect.** After each fix, promote the matching `warn` test to an error.

Work through the PRs in this order, which puts the highest risk of wrong numbers first.

#### PR-14 · `fix/paycheck-allocation`

**Problems:** Guilt-Free rows are missing in months with no guilt-free transactions (so the variance isn't 0), and any income not categorized `Paycheck` falls into `Other` and is dropped silently.

**Decision:** bonuses and extra paychecks are recorded as category `Paycheck`. A bonus then appears as a positive Paycheck variance (more came in than budgeted), which is the signal this model exists to give. No new allocation types are added.

**Before you change anything:** run `dbt test --select assert_guilt_free_variance_is_zero`. It should fail: that's the failing test from PR-13, so there is nothing new to commit. Copy the failing output into the PR description as your test-first evidence.


1. **Guilt-Free override in `final`.** Replace the `budget_guilt_free` and `adjusted_aggregated_transactions` CTEs with a single `final` that applies the override from the budget side, so every budgeted month has a row:
   ```sql
   final as (
       select
           budget.allocation_type,
           budget.budget_month,
           budget.budget_amount,
           case
               when budget.allocation_type = 'Guilt-Free' then budget.budget_amount
               else coalesce(transactions.allocation_amount, 0)
           end as allocation_amount
       from aggregated_budget as budget
       left join aggregated_transactions as transactions
           on transactions.allocation_type = budget.allocation_type
           and transactions.transaction_month = budget.budget_month
   )
   ```
   then compute `allocation_variance` in a following CTE (using `signed_variance` from PR-10). Remove the stray `order by 2, 1`.

   **Commit now:** `fix(marts): apply guilt-free override in final CTE`

2. **Enforce the "all income is Paycheck" rule with a test** instead of new rows. `Other` stays excluded from the model (transfers between your own accounts aren't income), so the test is what stops real income from falling into it. `tests/assert_all_income_is_paycheck.sql`:
   ```sql
   select transaction_month, transaction_category, total_amount
   from {{ ref('int_cashflow_transactions_agg_month') }}
   where transaction_type = 'Income'
     and transaction_category <> 'Paycheck'
   ```
   If it returns rows, recategorize those transactions as `Paycheck` in the sheet. Also update the `allocation_type` description in `_marts.yml`: "Paycheck: all budgeted income, including bonuses and extra paychecks".

   **Commit now:** `test(tests): require all income to be categorized as paycheck`

3. **Test-first:** the Guilt-Free test from PR-13 is your failing test. Also add a permanent monitor (keep it at `warn`; it's a check on your data, not a bug test) that each closed month's paycheck is fully allocated. `tests/assert_paycheck_fully_allocated.sql`:
   ```sql
   {{ config(severity='warn') }}
   select budget_month, paycheck, allocated, paycheck - allocated as unallocated
   from (
       select
           budget_month,
           sum(if(allocation_type = 'Paycheck', allocation_amount, 0)) as paycheck,
           sum(if(allocation_type <> 'Paycheck', allocation_amount, 0)) as allocated
       from {{ ref('fct_monthly_paycheck_allocation') }}
       where budget_month < date_trunc({{ today() }}, month)
       group by 1
   )
   where abs(paycheck - allocated) > 0.01
   ```
   A month that fails is either a bonus not yet assigned to a destination, or a plain data-entry gap.

   **Commit now (after you've added the monitor test):** `test(tests): monitor that each month's paycheck is fully allocated`

4. **Expected data changes:** new Guilt-Free rows for months with no transactions (variance 0). Nothing else changes, as long as all income is already categorized `Paycheck`. (`Other` rows are ignored automatically, since the final join starts from the budget side.)

**PR title:** `fix(marts): correct paycheck allocation for months without guilt-free spending`

**PR description** (paste into GitHub):

```markdown
## What changed
`fct_monthly_paycheck_allocation` now applies the Guilt-Free override in `final`, so every budgeted month has a row. Changes `like 'Guilt-Free'` to `=` and removes the unused `order by`. Adds a test that all income is categorized `Paycheck`, and a monitor that each closed month's paycheck is fully allocated.

## Why
Months with no guilt-free transactions had no Guilt-Free row, so the variance equalled the full budget instead of 0. Income outside `Paycheck` was silently dropped.

## How I verified it
The failing test from PR-13 (`assert_guilt_free_variance_is_zero`) now passes. `assert_all_income_is_paycheck` passes. [Add: or which transactions you recategorized in the sheet.]

## Does data change?
Yes. New Guilt-Free rows for months with no transactions (variance 0). Nothing else changes.
```

#### PR-15 · `fix/savings-goals-logic`

1. **Explicit window frames.** Without one, tied priorities get the same running total (`range` semantics). Change both windows:
   ```sql
   sum(goal_amount) over (
       partition by account_name
       order by goal_priority
       rows between unbounded preceding and current row
   ) as running_goal_amount,
   ```
   and the same for `running_goal_amount_needed` (`order by goal_status_id, goal_priority`).

   **Commit now:** `fix(marts): use explicit window frames in dim_savings_goals`

2. **Uniqueness test for priority.** In staging YAML: `unique` on `goal_priority` with `config: {where: "actual_date is null"}`. If your data has no ties today, this passes immediately: the bug is preventive, and the unit test in PR-28 reproduces it with tied priorities (this is the "test-first isn't possible" case).

   **Commit now:** `test(staging): add unique test on goal_priority`

3. **Use `today()`:** replace `current_date('America/Toronto')` with `{{ today() }}`. Document that the savings budget comes from the latest *transaction* month while `funding_month` counts from the calendar month.
4. **Document the assumptions** in the model description: all outstanding goals are funded sequentially from the one monthly Savings budget, and the `+ 1` month buffer covers the current partial month.

   **Commit now (after steps 3 and 4):** `fix(marts): use today() and document funding assumptions`

5. **Tidy the repeated columns.** Instead of re-listing every column in each CTE, add only what's new, e.g.:
   ```sql
   goals_amount_saved as (
       select
           *,
           greatest(0, least(goal_amount, account_current_balance - (running_goal_amount - goal_amount))) as goal_amount_saved
       from goals_accounts_balance
   )
   ```
   (This is equivalent to the current `case` and removes the duplicated expression and `account_balance_before`.)

   **Commit now:** `refactor(marts): select only new columns in dim_savings_goals CTEs`

6. **Verify:** no data change on today's data (compare to the baseline, excluding `funding_month` if the timezone changes a day boundary).

**PR title:** `fix(marts): use explicit window frames and project timezone in dim_savings_goals`

**PR description** (paste into GitHub):

```markdown
## What changed
In `dim_savings_goals`: explicit `rows between unbounded preceding and current row` frames, `today()` instead of `current_date('America/Toronto')`, repeated column lists replaced by `select *, ...`, and the `+ 1` month buffer and sequential funding assumption documented. Adds a `unique` test on `goal_priority`.

## Why
Tied priorities would double-count the running totals, and the model used two definitions of 'now'.

## How I verified it
`dbt build` passes and the new unique test passes (no tied priorities today). `compare_to_baseline.sql` on `dim_savings_goals`, excluding `funding_month` if the timezone moves a day boundary. The tied-priority behaviour gets a unit test in PR-28.

## Does data change?
No, on today's data.
```

#### PR-16 · `fix/budget-vs-actual-open-months`

1. Add `is_future_month` to `fct_budget_vs_actual`, `fct_budget_vs_actual_fixed_costs`, `fct_budget_vs_actual_guilt_free` (and optionally the allocation model):
   ```sql
   budget_month > date_trunc({{ today() }}, month) as is_future_month
   ```
   Add it to `_marts.yml` as a boolean, `not_null`. The flag is true only for months after the current one, so the **current, partial month stays visible** with its spending so far, and dashboards can hide the months that haven't started yet instead of showing them as "underspent". (An earlier version of this plan flagged closed months, `is_closed_month`, which would have hidden the current month too.)

   **Commit now:** `feat(marts): add is_future_month to budget-vs-actual facts`

2. **Guilt-Free running totals carry over across years** (decided; this matches the allocation model, where underspend carries over). Keep the SQL as it is and correct the wording in `_marts.yml`: change "cumulative, year-to-date" in the model description to "cumulative since the first month in the data (unspent budget carries over across years)", and make sure the three `running_*` column descriptions say the same. No data changes.

   **Commit now:** `docs(marts): correct guilt-free running total description`

3. A brand-new column can't have a failing test first. Instead add `accepted_values: [true, false]` and a singular test that no month on or before the current month is marked as a future month.

   **Commit now:** `test(marts): add tests that current and past months are not future months`

**PR title:** `feat(marts): add is_future_month and correct guilt-free running total wording`

**PR description** (paste into GitHub):

```markdown
## What changed
Adds `is_future_month` to `fct_budget_vs_actual`, `fct_budget_vs_actual_fixed_costs` and `fct_budget_vs_actual_guilt_free`. Corrects the Guilt-Free description: running totals are cumulative and carry over across years.

## Why
Future months showed as underspent, and the description said 'year-to-date' for totals that never reset.

## How I verified it
`dbt build` passes. New `not_null` and `accepted_values` tests on the flag, and a singular test that no month on or before the current month is marked as a future month.

## Does data change?
One new boolean column. Existing columns are unchanged.
```

### Interlude — extra PR, data feed and source freshness (after PR-16, before PR-17)

Three things happen between PR-16 and PR-17: a small PR to the baseline helpers (PR-16a), the fictional data feed (Task G), and source freshness (PR-12, moved here from Phase 4). The order matters: freshness only means something once data arrives regularly, and the feed changes how you compare against the baseline.

#### PR-16a · `chore/baseline-compare-exclude-volatile-columns`

**Goal:** stop the baseline helpers from reporting differences that come from live prices and today's date, and make the one-model helper show the actual differing rows. No data changes.

1. **Exclude the time-dependent columns in `analyses/compare_all_to_baseline.sql`.** After you synced newer prices, some columns differed between your dev build and Production although no code changed, because they depend on values that move during the day. Replace the `excluded_columns` setting with:
   ```sql
   {% set excluded_columns = {
       'dim_investments': ['annualized_return_rate'],
       'retirement_projection': ['current_value', 'future_value']
   } %}                                    {# price- or date-driven columns, per model #}
   ```
   If `compare_totals_to_baseline.sql` flags the same columns (it sums every numeric column), use the same lists there. Add `latest_price` or `current_value` to `dim_investments` if your prices move between the two builds.
2. **Show the differing rows in `analyses/compare_to_baseline.sql`.** Add `summarize = false` to the `audit_helper.compare_relations` call:
   ```sql
   {{ audit_helper.compare_relations(
       a_relation = ref(model_name),
       b_relation = api.Relation.create(
           database = target.database,
           schema = baseline_schema,
           identifier = model_name
       ),
       exclude_columns = excluded_columns,
       primary_key = primary_key,
       summarize = false
   ) }}
   ```
   Without it the macro returns only counts. With it, you see the rows that differ. That is what you need, because you open this helper only after `compare_all_to_baseline.sql` has found a difference. (Check the `audit_helper` docs for your version if the argument isn't accepted.)

   **Commit now:** `chore(analyses): exclude time-dependent columns from baseline comparison`

3. **Verify:** build in dev (Defer = **Development**), run **Baseline: build main**, then run `compare_all_to_baseline.sql` with and without the exclusions to see the difference, and `compare_to_baseline.sql` on `dim_investments` to see the rows.
4. **Remember for PR-25:** when `retirement_projection` is renamed to `rpt_retirement_projection`, change its key in `excluded_columns` in both analyses.

**PR title:** `chore(analyses): exclude time-dependent columns from baseline comparison`

**PR description** (paste into GitHub):

```markdown
## What changed
Updates `compare_all_to_baseline.sql` to exclude columns that change with live prices: `annualized_return_rate` in `dim_investments`, and `current_value` and `future_value` in `retirement_projection`. Sets `summarize = false` in `compare_to_baseline.sql` so it lists the individual differing rows.

## Why
Those columns depend on prices that can change during the day, so they showed differences that were not caused by a code change. `compare_to_baseline.sql` is only run when `compare_all_to_baseline.sql` finds differences, so it makes sense for it to show the row-level detail.

## How I verified it
Synced the data in Fivetran to get more recent prices from `investments_price`. Ran `compare_all_to_baseline.sql` without the exclusions and with them. Ran `compare_to_baseline.sql` to see the specific rows that differ.

## Does data change?
No.
```

#### Task G · Sheet data generator (Google Apps Script, no dbt PR)

**Goal:** new rows arrive in the `Transactions` and `Investments` tabs every day, so Fivetran has something to sync, the models keep moving and source freshness (PR-12) means something. The data is fictional, so a rule-based script is a legitimate feed.

**What the script does** (`generate_transactions.gs`): every day it appends the rows for each day after the latest date in the sheet, up to yesterday and never past `END_DATE` (31 Dec 2026, the end of the 2026 budget). The rules come from your own data:

- Biweekly paychecks (two rows), then on the first payday of the month a savings transfer and a TFSA transfer for each person, with the matching ETF buys in `Investments`.
- Monthly fixed costs (rent, insurance, transit, internet, phone, electricity, pet food), grocery trips on Kenji's card, and Guilt-Free spending drawn from your existing rows.
- Interest and cashback, credit card payments that clear the cards, and a month-end surplus that goes to the TFSAs (or to savings in months with three paychecks).
- ETF buy prices from `GOOGLEFINANCE` closing prices (last close on or before the date), with a random-walk fallback if no quote comes back.

It is idempotent (a rerun adds nothing, the same day always produces the same rows) and every row uses a valid type, category and account from your data. I tested the logic offline against your two CSVs, not inside Google Sheets.

**Steps**

1. **Install it.** In the Sheet: **Extensions → Apps Script**, paste `generate_transactions.gs`. In **Project Settings** tick **Show "appsscript.json" manifest file** and set `"timeZone": "America/Toronto"`. Check that `CONFIG.TX_SHEET` and `CONFIG.INV_SHEET` match your tab names.
2. **Run it.** Pick `dryRun` in the function dropdown and click **Run** (nothing is written). Then `appendDailyData` for the real backfill, then `installDailyTrigger` once to schedule a daily run at about 05:00. The first run asks you to authorise the script: **Advanced → Go to (project) (unsafe) → Allow**. The warning appears because Google hasn't reviewed a script you wrote yourself.
3. **Check the sheet.** New rows start the day after your last date. In the Apps Script **Execution log** each ETF buy says `GOOGLEFINANCE close` or `random walk (no quote)`. If a ticker falls back, check `CONFIG.EXCHANGE_PREFIX` (`TSE:`).
4. **Check the `accounts` tab.** The `assert_account_balances_match_sheet` test (PR-13) compares the balances dbt calculates with the sheet's `current_balance`. If that column is a formula over the transactions, nothing to do. If the balances are typed values, the test will start failing, because the script doesn't update them. Either make the sheet calculate them, or accept the failure as a monitor and note it in the test.
5. **Set the Fivetran sync frequency** to at least daily (connector → **Setup** → sync frequency), then click **Sync now** once.
6. **Check dbt.** Set **Defer** to **Development** and run `dbt build --exclude package:dbt_project_evaluator`. Read the failures. A new failure in `accepted_values`, `relationships` or `assert_transaction_categories_exist` means a generator rule produced a value your reference tables don't know: fix the value in the script. `fct_cashflow_transactions` and `fct_investments_transactions` should have more rows, and the budget-vs-actual facts should now include September and October.
7. **Refresh the baseline.** Run **Baseline: build main** so Production includes the new data. From now on, run it right before each comparison, and build your dev branch straight afterwards, so a morning sync can't land between the two builds.
8. **To pause the feed** (for example while you compare a fix against a frozen baseline): Apps Script → the **Triggers** clock icon → delete the trigger. Run `installDailyTrigger` again to resume.
9. **Publish the script (optional).** The sheet template lives in the companion repository `personal_finances`, so that is the natural home: on GitHub choose **Add file → Upload files**, add `generate_transactions.gs` and commit. If you prefer to keep it in this repository, create a `scripts/` folder in the IDE and use a PR titled `docs: add Google Sheets data generator script`. The script contains no credentials and no sheet ID. Then add the link to the README, in "Keeping the data fresh".
10. **When the 2027 budget exists:** change `CONFIG.END_DATE` in the script. The new budget year checklist in the style guide has a step for it.

#### PR-12 · `test/source-freshness` (moved here)

**Why it moved.** With static data `_fivetran_synced` never changes, so any short threshold warns forever, and a check that always warns teaches you to ignore it. With the feed from Task G, the transaction sheets receive new rows every day, so `max(_fivetran_synced)` moves daily and a tight threshold now says something real: the feed or the Fivetran connector stopped.

A correction to an earlier note: `_fivetran_synced` is not "when a row last changed". Fivetran's own staff describe it as sync timing, and it can update on a full resync even when the row didn't change. Freshness uses the latest value in the table, so appended rows keep it current either way.

1. **Look at the real ages first.** Create a scratch file in `analyses/`, click **Preview**, then revert or delete it:
   ```sql
   select 'cashflow_transactions' as source_table, max(_fivetran_synced) as last_synced
   from {{ source('google_sheets', 'cashflow_transactions') }}
   union all
   select 'investments_transactions', max(_fivetran_synced)
   from {{ source('google_sheets', 'investments_transactions') }}
   union all
   select 'investments_price', max(_fivetran_synced)
   from {{ source('google_sheets', 'investments_price') }}
   union all
   select 'accounts', max(_fivetran_synced)
   from {{ source('google_sheets', 'accounts') }}
   ```
   Use the table names from your `_src_google_sheets.yml`. A threshold only helps if it would fire when something is really wrong, so pick it a little above the longest normal gap.
2. **Configure freshness** in `_src_google_sheets.yml`: generous defaults on the source for the reference sheets (budgets, accounts, goals, assumptions, category list), and tight overrides on the three that change:
   ```yaml
   sources:
     - name: google_sheets
       config:
         loaded_at_field: _fivetran_synced
         freshness:                       # default: sheets you rarely edit
           warn_after: {count: 90, period: day}
           error_after: {count: 365, period: day}
       tables:
         - name: cashflow_transactions    # written daily by the generator
           config:
             freshness:
               warn_after: {count: 36, period: hour}
               error_after: {count: 3, period: day}
         - name: investments_transactions # same
           config:
             freshness:
               warn_after: {count: 36, period: hour}
               error_after: {count: 3, period: day}
         - name: investments_price        # prices change on trading days
           config:
             freshness:
               warn_after: {count: 4, period: day}
               error_after: {count: 10, period: day}
   ```
   (In older dbt versions `loaded_at_field` and `freshness` sit directly under the source, not under `config`. Keep the `tables:` entries you already have and add only the `config:` blocks.) The 36 hours tolerate one late day; the 4 days on `investments_price` cover a weekend or a market holiday without a price change. If the connector's gaps turn out longer, loosen the numbers.

   **Commit now:** `test(config): add source freshness checks`

3. **Run `dbt source freshness`** in the command bar. The three tight sources should pass if the trigger and Fivetran are running. If one warns, check Apps Script **Executions** (did the trigger run?) and the Fivetran connector (did it sync?).
4. **Check the evaluator.** Run `dbt build --select package:dbt_project_evaluator`. The `fct_sources_without_freshness` warning you saw in PR-11 should be gone. If it still lists a table, that table's freshness is probably set to `null`: give it generous thresholds like the defaults above.
5. **Leave "Run source freshness" off** in your jobs for now, so a stale source can't fail the baseline job while you tune the thresholds. Write the thresholds and the reason in the PR description, and later in the README.

**PR title:** `test(config): add source freshness checks`

**PR description** (paste into GitHub):

```markdown
## What changed
Adds source freshness checks on `_fivetran_synced`: warn after 36 hours and error after 3 days on `cashflow_transactions` and `investments_transactions`, 4 and 10 days on `investments_price`, and 90 and 365 days as the default for the reference sheets.

## Why
Stale sheet data was invisible. The two transaction sheets now receive rows daily from the data generator, so a tight threshold detects a stopped feed or connector. The reference sheets rarely change, so a long threshold only catches a dead connector.

## How I verified it
`dbt source freshness` runs. [Add the result: passes, or which source warns.] The `fct_sources_without_freshness` finding from `dbt_project_evaluator` no longer appears.

## Does data change?
No.
```


#### PR-17 · `fix/fixed-costs-unbudgeted-spend`

1. The PR-13 actuals reconciliation test is your failing test.
2. In `fct_budget_vs_actual_fixed_costs`, replace the `left join` with a `full outer join` so categories that have spending but no budget row appear with `budget_amount = 0`:
   ```sql
   select
       coalesce(budget.budget_category, actual.transaction_category) as budget_category,
       coalesce(budget.budget_month, actual.transaction_month) as budget_month,
       coalesce(budget.budget_amount, 0) as budget_amount,
       coalesce(actual.actual_amount, 0) as actual_amount,
       coalesce(budget.budget_amount, 0) - coalesce(actual.actual_amount, 0) as variance_amount
   from budget_fixed_costs as budget
   full outer join actual_agg_category_fixed_costs as actual
       on actual.transaction_category = budget.budget_category
       and actual.transaction_month = budget.budget_month
   ```
   Rebuild the key with `slug_key(['budget_category'], 'budget_month')`, since it can no longer come from the budget side.

   **Commit now:** `fix(marts): include unbudgeted fixed-cost spend in budget vs actual`

3. The existing `accepted_values` test on `budget_category` will now flag a typo'd or new category, which is the point.

   Now that the fix makes them pass, remove `{{ config(severity='warn') }}` from `tests/assert_fixed_costs_actuals_match_categories.sql` (and from the budget test, if it passes) so a regression fails the build.

   **Commit now:** `test(tests): promote fixed-costs reconciliation tests to errors`

4. **Expected data change:** new rows only where fixed-cost spending existed without a budget row.

**PR title:** `fix(marts): include unbudgeted fixed-cost spend in budget vs actual`

**PR description** (paste into GitHub):

```markdown
## What changed
`fct_budget_vs_actual_fixed_costs` now uses a `full outer join`, so fixed-cost spending in categories without a budget row appears with `budget_amount = 0`. The key is rebuilt with `slug_key`.

## Why
Unbudgeted fixed-cost spending was silently dropped, so actuals didn't reconcile with the `Fixed Costs` total.

## How I verified it
The reconciliation test from PR-13 (`assert_fixed_costs_actuals_match_categories`) now passes and is promoted to an error.

## Does data change?
Yes. New rows only where fixed-cost spending existed without a budget row. [List them.]
```

#### PR-18 · `fix/dim-dates-range`

**Problem:** the start date uses all three sources but the end date uses only the last cashflow transaction. A 2027 budget loaded before any 2027 transactions would fall outside `dim_dates`.

1. Failing test first, `tests/assert_dim_dates_covers_budget_months.sql` (it passes today, but fails the day a 2027 budget is added; that's what it protects):
   ```sql
   select budget_month
   from {{ ref('int_budget') }}
   where budget_month not in (select calendar_date from {{ ref('dim_dates') }})
   ```

   **Commit now (commit the test first, then run it to see it pass today):** `test(tests): assert dim_dates covers all budget months`

2. In `dim_dates.sql`, take the end date from all three sources, mirroring the `min_dates` CTE:
   ```sql
   max_dates as (
       select max(budget_month) as max_date from budget
       union all
       select max(transaction_date) from cashflow_transactions
       union all
       select max(event_date) from investments_transactions
   ),
   end_date as (
       select last_day(max(max_date), year) as max_all_dates from max_dates
   )
   ```
   and use `max_all_dates` in `generate_date_array`.

   **Commit now:** `fix(marts): derive dim_dates end date from all sources`

3. Add `date_trunc(single_date, month) as month_start_date` to `final` so monthly facts can join on it. Update `_marts.yml`: the new column, and the description ("…through the end of the year containing the latest budget or transaction date").

   **Commit now:** `feat(marts): add month_start_date to dim_dates`

4. **Expected data change:** none today (the budget already ends in December 2026).

**PR title:** `fix(marts): extend dim_dates range to all sources`

**PR description** (paste into GitHub):

```markdown
## What changed
`dim_dates` takes its end date from the latest budget month, cashflow transaction and investment event, not just the last cashflow transaction. Adds `month_start_date`.

## Why
A budget loaded for a new year before any transactions would fall outside the date dimension.

## How I verified it
New test `assert_dim_dates_covers_budget_months` passes and `dbt build` passes.

## Does data change?
No rows change today, since the budget already ends in December 2026. One new column.
```

#### PR-19 · `fix/investments-position`

1. **Check how dividends are recorded** before touching the XIRR input:
   ```sql
   select investment_event, count(*) as n, sum(total_value) as sum_total_value,
          sum(dividends) as sum_dividends, sum(net_quantity) as sum_net_quantity
   from {{ ref('stg_google_sheets__investments_transactions') }}
   group by 1
   ```
   `dim_investments` only feeds `total_value` into XIRR. If `Dividends` rows carry the cash in `dividends` and leave `total_value` empty or 0, dividend income is missing from the return. Decide which column is the cash flow and make the model use it. Also check that `Dividends` rows have `net_quantity = 0` (add a singular test).

   **Commit now (after you've added the singular test):** `test(tests): assert dividends rows have zero net quantity`

2. In `dim_investments`: `safe_cast( ... )` → `cast( ... )`, so an unexpected value fails loudly. Replace `current_date()` with `{{ today() }}`.

   **Commit now:** `fix(marts): use cast and today() in dim_investments`

3. Make sure the `unique` test on `ticker` (from PR-13) is promoted to an error. If it fails, a name or type typo in the sheet is splitting a position; fix the sheet.

   **Commit now:** `test(marts): promote unique ticker test to error`

4. Add a note to `annualized_return_rate` in `_marts.yml`: positions held only a short time can show extreme annualized rates.

   **Commit now:** `docs(marts): note extreme annualized rates for short holding periods`

5. **Expected data change:** none, unless the dividend check finds a real gap.

**PR title:** `fix(marts): tighten casts and dividends handling in dim_investments`

**PR description** (paste into GitHub):

```markdown
## What changed
`dim_investments`: `cast` instead of `safe_cast`, `today()` instead of `current_date()`, a note on extreme annualized rates for short holding periods, and a test that `Dividends` rows have `net_quantity = 0`. The `unique` test on `ticker` is promoted to an error.

## Why
`safe_cast` hid bad values, and I needed to confirm that dividends reach the XIRR input.

## How I verified it
Checked how dividends are recorded. [Add the result.] `dbt build` passes and the unique `ticker` test passes.

## Does data change?
No. [Unless the dividend check found a gap: describe it.]
```

#### PR-20 · `fix/retirement-projection`

1. **Failing unit test first** (the zero-rate bug is hard to reproduce with a data test). In `models/marts/_unit_tests.yml`:
   ```yaml
   unit_tests:
     - name: retirement_projection_zero_rate
       model: retirement_projection
       given:
         - input: ref('stg_google_sheets__retirement_assumptions')
           rows:
             - {current_age: 40, retirement_age: 65, projected_interest_rate: 0}
         - input: ref('int_investments_current_position')
           rows:
             - {current_value: 10000}
         - input: ref('int_budget_latest_month')
           rows:
             - {budget_type: 'Investments', budget_amount: 500}
       expect:
         rows:
           - {future_value: 160000}
   ```
   Expected: 10,000 + 500 × 12 × 25 = 160,000. Today the result is null.

   **Commit now (run `dbt test --select test_type:unit` first and confirm it fails, then commit (CI isn't blocking yet, so a failing commit is fine on this branch)):** `test(marts): add failing unit test for a zero interest rate`

2. **Fix** in `retirement_projection.sql`:
   - Rename `monthly_rate` to `growth_factor`, since it's the compounded factor `(1 + r/12)^n`, not a rate.
   - Handle a 0% rate for the contribution term (the `nullif` currently nulls the *entire* result):
     ```sql
     round(
         current_value * growth_factor
         + case
             when projected_interest_rate = 0 then monthly_contribution * contribution_years * 12
             else 12 * monthly_contribution * (growth_factor - 1) / projected_interest_rate
         end,
         2
     ) as future_value
     ```
   - Remove `limit 1` (the source has one row per budget type, enforced by a unique test).

   **Commit now:** `fix(marts): handle 0% rate and rename growth factor in retirement_projection`

3. Document the assumptions in the YAML description: nominal return, no inflation, no taxes, constant contribution, contributions at the end of each month.

   **Commit now:** `docs(marts): document retirement projection assumptions`

4. **Expected data change:** none at your current (non-zero) rate.

**PR title:** `fix(marts): handle a 0% rate in retirement_projection`

**PR description** (paste into GitHub):

```markdown
## What changed
`retirement_projection`: handles a 0% rate in the contribution term, renames `monthly_rate` to `growth_factor`, and removes `limit 1`. Documents the assumptions. Adds a unit test for a 0% rate.

## Why
At a 0% rate `nullif` made the entire future value null, and `monthly_rate` was really a compounded factor.

## How I verified it
The new unit test `retirement_projection_zero_rate` failed before the fix and passes now (expected 160,000). `dbt build` passes.

## Does data change?
No, at the current non-zero rate.
```

#### PR-21 · `fix/dim-cashflow-types-ordering`

**Problem:** `row_number() over()` has no ordering, so the `flowtypeNN` IDs may differ between runs.

1. Replace the `row_number()` key with the stable readable key (decided):
   ```sql
   added_key as (
       select
           {{ slug_key(['cashflow_type']) }} as cashflow_type_id,
           cashflow_type
       from selected_columns
   )
   ```
   IDs look like `fixedcosts` or `guiltfreepet`. They never change when a type is added or removed, which matters once facts reference this key (PR-24).

   **Commit now:** `fix(marts): build cashflow type ids from slug_key`

2. A failing test isn't practical here (the bug is non-deterministic row ordering). Say so in the PR. The existing `unique` and `not_null` tests on the ID still apply.
3. **Expected data change:** the ID values change (`flowtype01` becomes a slug). Nothing references them yet. Update the `cashflow_type_id` description in `_marts.yml` ("slug of `cashflow_type`").

**PR title:** `fix(marts): build cashflow type ids from slug_key`

**PR description** (paste into GitHub):

```markdown
## What changed
`dim_cashflow_types.cashflow_type_id` is now built with `slug_key` instead of `row_number()`.

## Why
The ids depended on unordered row numbering and would change whenever a type was added.

## How I verified it
`dbt build` passes, and `unique` and `not_null` still pass. No failing test is practical for a non-deterministic ordering bug.

## Does data change?
Yes. `cashflow_type_id` values change (`flowtype01` becomes a slug such as `fixedcosts`). Nothing references them yet.
```

#### PR-22 · `fix/staging-null-handling` (do last in this phase, as it may expose blank cells)

1. **Before changing anything**, run `dbt test --select source:google_sheets`. Your source tests already require the budget and account columns to be non-null. If they all pass, removing the `coalesce` changes no data.
2. In `stg_google_sheets__accounts` and `stg_google_sheets__budget_2026`, remove `coalesce( ..., 0 )`, leaving only the cast. Keep `coalesce` on `dividends` (blank means 0 there) with a comment.
3. `current_balance_sheet` was also coalesced: now it stays null when the sheet has no value. That's accurate; PR-13's balance test treats null as a mismatch.
4. The `not_null` tests on the staging month columns (`_stg_google_sheets.yml`) are now meaningful.
5. **Sheet rule:** an empty month cell is an error. Type `0` instead. A blank would silently drop that row in the `unpivot`.
6. If new failures appear, fix the cells in the sheet; don't re-add the coalesce.

   **Commit now (once `dbt test` passes with the coalesces removed):** `fix(staging): stop coalescing blanks to zero in accounts and budget`

**PR title:** `fix(staging): stop coalescing blank budget and account values to zero`

**PR description** (paste into GitHub):

```markdown
## What changed
Removes `coalesce(..., 0)` from `stg_google_sheets__accounts` and `stg_google_sheets__budget_2026`. Keeps it on `dividends`, with a comment.

## Why
Blank cells and true zeros were indistinguishable, so the source `not_null` tests could never fail.

## How I verified it
Ran `dbt test --select source:google_sheets` before the change (all passing). `dbt build` passes after. [Add any blank cells you fixed in the sheet.]

## Does data change?
No, if the source tests passed. Blank cells now stay null.
```

**Checkpoint (end of phase 5):**
1. Promote warnings: search for `severity: warn` in YAML and `severity='warn'` in `tests/`. Remove each one that now passes. Keep `warn` only for monitors like `assert_paycheck_fully_allocated`, with a comment.
2. `dbt build` must be fully green.
3. Release: open a PR that sets `version: '1.1.0'` in `dbt_project.yml` (`chore(release): bump version to 1.1.0`) and merge it. Then on GitHub go to **Releases → Draft a new release**, choose **Create new tag on publish**, type `v1.1.0`, target `main`, add a short description ("Phase 5: correctness fixes") and **Publish release**. GitHub creates the tag.

### Phase 6 — Structure and interface (breaking, release v2.0.0)

These change names and add columns. Anything outside dbt that reads the marts (a dashboard, a sheet) needs updating when they merge.

#### PR-23 · `refactor/staging-rename-investments-price`

1. In the IDE file tree, right-click `stg_google_sheets__investments_prices.sql` → **Rename** → `stg_google_sheets__investments_price.sql`.
2. Find every reference: open the command palette (Cmd/Ctrl+P) → **Search for Text** → `investments_prices`. Update `int_investments_current_position.sql` and the `name:` in `_stg_google_sheets.yml` (and any docs). The search results can be sent to search and replace for a bulk change.
3. Run `dbt build` (Defer = Development); the baseline comparison on the marts must be clean.

   **Commit now (once the build is green (the `!` is optional here, see step 5)):** `refactor(staging)!: rename stg_google_sheets__investments_prices`

4. The old view stays in BigQuery, in your dev dataset and in Production after the next baseline run. Drop it in the BigQuery console (`drop view ...`) once the build is green.
5. Staging models aren't public, so the `!` in the commit message is optional.

**PR title:** `refactor(staging)!: rename investments_prices staging model to investments_price`

**PR description** (paste into GitHub):

```markdown
## What changed
Renames `stg_google_sheets__investments_prices` to `stg_google_sheets__investments_price` and updates the refs and YAML.

## Why
The staging model name now matches the source table name.

## How I verified it
`dbt build` passes and the marts match the baseline.

## Does data change?
No. The staging view is renamed, and I dropped the old view in BigQuery.
```

#### PR-24 · `feat/fact-dimension-keys`

1. Add a date-key macro in `macros/date_key.sql` that reproduces `dim_dates.date_id`:
   ```sql
   {% macro date_key(column_name) %}
       cast(format_date('%Y%m%d', {{ column_name }}) as int64)
   {% endmacro %}
   ```

   **Commit now:** `feat(macros): add date_key macro`

2. `fct_cashflow_transactions`: add
   - `account_id`, via a `left join` to `dim_accounts` on `account_name` (account names are unique, so this can't multiply rows)
   - `cashflow_category_id`, via a join to `dim_cashflow_categories` on **both** `cashflow_type` and `cashflow_category` (a category name can appear under more than one type)
   - `{{ date_key('transaction_date') }} as date_id`
3. `fct_investments_transactions`: add `account_id` and `{{ date_key('event_date') }} as date_id`.

   **Commit now (after steps 2 and 3):** `feat(marts): add account, category and date keys to transaction facts`

4. Use `left join` plus `not_null` and `relationships` tests on the new keys. An inner join would silently drop transactions with an unknown account, while the tests surface them.
5. Update `_marts.yml` for every new column.

   **Commit now (after steps 4 and 5, so the new tests and column docs go in together):** `test(marts): add fact-to-dimension relationships`

6. **Verify:** row counts per fact identical to before; `compare_relations` with `exclude_columns` set to the new columns shows no other differences.

**PR title:** `feat(marts): add account, category and date keys to transaction facts`

**PR description** (paste into GitHub):

```markdown
## What changed
Adds `account_id`, `cashflow_category_id` and `date_id` to `fct_cashflow_transactions`, and `account_id` and `date_id` to `fct_investments_transactions`. Adds a `date_key` macro and `relationships` tests.

## Why
The facts only carried names, so renaming an account in the sheet would break joins.

## How I verified it
Row counts per fact are identical to before. `compare_relations` with the new columns excluded shows no other differences. The new keys pass `not_null` and `relationships`.

## Does data change?
New columns only. Row counts and existing columns are unchanged.
```

#### PR-25 · `refactor/reporting-models`

1. Rename `retirement_projection` to `rpt_retirement_projection`: rename the file in the IDE (right-click → **Rename**), update `name:` in `_marts.yml`, and update `ref()` in `tests/assert_retirement_projection_single_row.sql` and the unit test from PR-20, and change the model's key in `excluded_columns` in `analyses/compare_all_to_baseline.sql` (and `compare_totals_to_baseline.sql` if you changed it there). Drop the old table in BigQuery afterward.

   **Commit now:** `refactor(marts)!: rename retirement_projection to rpt_retirement_projection`

2. **Keep the derived metrics in `dim_savings_goals` and `dim_investments` as a documented exception** (decided). The style guide section 5.3 already names the exception. Add a sentence to each model's description in `_marts.yml`, for example: "Exception to the dimension rule: this model also holds derived metrics (funding status and projected funding month) because it stays one row per goal." For `dim_investments`, name the XIRR return instead.

   **Commit now:** `docs(marts): document derived-metrics exception`

**PR title:** `refactor(marts)!: rename retirement_projection to rpt_retirement_projection`

**PR description** (paste into GitHub):

```markdown
## What changed
Renames `retirement_projection` to `rpt_retirement_projection` and documents the derived-metrics exception in the descriptions of `dim_savings_goals` and `dim_investments`.

## Why
Style guide: single-row reporting models use the `rpt_` prefix, and exceptions to the dimension rule should be explicit.

## How I verified it
`dbt build` passes, and the refs in the test and the unit test are updated. I dropped the old table in BigQuery.

## Does data change?
No data change. The table name changes, so anything reading `retirement_projection` must be updated.
```

#### PR-26 · `chore/layer-schemas`

dbt Cloud has two details that matter here. The Production environment (deployment type **Production**) sets the variable `DBT_CLOUD_ENVIRONMENT_TYPE` to `prod`, and the IDE sets it to `dev`. And CI jobs build into temporary schemas whose names start with `dbt_cloud_pr_`: dbt Cloud only drops those automatically after the PR closes if the schema name still starts with that prefix, so the macro below preserves it.

1. **Check the variable in your environments.** In a scratch file in `analyses/` run **Preview** on `select '{{ env_var("DBT_CLOUD_ENVIRONMENT_TYPE", "") }}' as environment_type`. In the IDE it should say `dev`. The Production environment must be set to deployment type **Production** (Baseline step 1) so that it resolves to `prod`.
2. **Add `macros/generate_schema_name.sql`:**
   ```sql
   {% macro generate_schema_name(custom_schema_name, node) -%}
       {%- set default_schema = target.schema -%}
       {%- if custom_schema_name is none -%}
           {{ default_schema }}
       {%- elif env_var('DBT_CLOUD_ENVIRONMENT_TYPE', '') == 'prod' -%}
           {{ custom_schema_name | trim }}
       {%- else -%}
           {{ default_schema }}_{{ custom_schema_name | trim }}
       {%- endif -%}
   {%- endmacro %}
   ```
   Production gets `staging`, `intermediate` and `marts`. The IDE gets `dbt_<you>_staging` and so on. A CI run gets `dbt_cloud_pr_<job>_<pr>_marts` and so on, which keeps the prefix. Never let the IDE use the clean names: if your development credentials can write to the same project, it would overwrite the Production tables.

   **Commit now:** `chore(macros): override generate_schema_name`

3. **Set the schema per layer** in `dbt_project.yml`:
   ```yaml
   models:
     personal_finances:
       staging:
         +materialized: view
         +schema: staging
       intermediate:
         +materialized: view
         +schema: intermediate
       marts:
         +materialized: table
         +schema: marts
   ```

   **Commit now (after the baseline comparison in step 5 passes (you can commit earlier and amend if you prefer)):** `chore(config)!: build each layer into its own dataset`

4. **Build in the IDE** (Defer = Development) and check that the new datasets exist in BigQuery (`dbt_<you>_staging`, `dbt_<you>_intermediate`, `dbt_<you>_marts`). To list them from the IDE, run **Preview** on this query in a scratch file (adjust the region):
   ```sql
   select table_schema, count(*) as tables
   from `{{ target.database }}`.`region-us`.INFORMATION_SCHEMA.TABLES
   group by 1
   ```
5. **Compare with the baseline.** Production hasn't been rebuilt yet, so it still has the old layout: leave `layered = false` (and `baseline_schema` as `analytics`) in `analyses/compare_all_to_baseline.sql`, and `baseline_schema` as `analytics` in `analyses/compare_to_baseline.sql` and check that row counts and totals match for every model.
6. **After the PR merges**, run **Baseline: build main**. Production now builds into `staging`, `intermediate` and `marts`. Then:
   - set `layered = true` in `analyses/compare_all_to_baseline.sql`, and update `baseline_schema` in `analyses/compare_to_baseline.sql` to `marts` (or `intermediate` / `staging` for those models);
   - repoint anything that reads the old Production tables;
   - **drop the old tables and views** from the old Production dataset (`analytics`) in the BigQuery console. Keep the XIRR function, which still lives in that base dataset. Don't delete anything until the new build is verified.

**PR title:** `chore(config)!: build each layer into its own dataset`

**PR description** (paste into GitHub):

```markdown
## What changed
Builds each layer into its own dataset (`staging`, `intermediate`, `marts`) with a `generate_schema_name` override: Production gets the clean names, while the IDE and CI get prefixed names that keep the `dbt_cloud_pr_` prefix.

## Why
Per-layer datasets allow per-layer access, give consumers a clear surface, and let me rebuild a layer by dropping one dataset.

## How I verified it
Confirmed `DBT_CLOUD_ENVIRONMENT_TYPE` is `dev` in the IDE. Built in the IDE and compared every model with the baseline: row counts and totals match. After merging, I ran the baseline job and dropped the old tables from the old dataset.

## Does data change?
No data change, but Production tables move to new datasets. Anything reading the old locations must be repointed.
```

#### PR-27 · `feat/mart-contracts`

An enforced contract makes dbt fail the build if a model's columns or types don't match its YAML. Every column needs a `data_type`.

1. Get the current types:
   ```sql
   select table_name, column_name, data_type
   from `personal-finances-501019.<marts dataset>.INFORMATION_SCHEMA.COLUMNS`
   order by table_name, ordinal_position
   ```
2. Add to each mart in `_marts.yml`:
   ```yaml
   - name: dim_accounts
     config:
       contract:
         enforced: true
       access: public
       meta:
         owner: <your name>
         domain: accounts
       tags: [accounts]
     columns:
       - name: account_id
         data_type: int64     # use the type from step 1
   ```
   Use BigQuery type names (`int64`, `string`, `numeric`, `date`, `float64`, `bool`, `timestamp`). The columns listed must match the model's select exactly, in name and number.

   **Commit now (do the dimension models first, run `dbt build`, then commit):** `feat(marts): enforce contracts on dimensions`

3. Do it in two commits (dimensions, then facts), as the plan says. Set `access: protected` on staging and intermediate models, if you want the rule enforced.

   **Commit now (after the fact models build with contracts enforced):** `feat(marts): enforce contracts on facts`

4. **Exposures.** If anything consumes the marts outside dbt, describe it in `models/marts/_exposures.yml`:
   ```yaml
   exposures:
     - name: budget_dashboard
       type: dashboard
       maturity: low
       owner:
         name: <your name>
         email: <your email>
       depends_on:
         - ref('fct_budget_vs_actual')
         - ref('fct_budget_vs_actual_guilt_free')
   ```
   Skip it if there's no consumer yet.

   **Commit now:** `feat(config): add exposures and meta`

5. From here, any change to a mart's columns must also change its YAML.

**PR title:** `feat(marts): enforce contracts and add meta and exposures`

**PR description** (paste into GitHub):

```markdown
## What changed
Enforces contracts with `data_type` on every mart column, sets `access: public` on marts, and adds `meta`, tags and exposures.

## Why
A mart's columns and types become a stable interface: the build fails if they drift.

## How I verified it
`dbt build` passes with contracts enforced. Types were taken from `INFORMATION_SCHEMA`.

## Does data change?
No.
```

#### PR-28 · `test/unit-tests`

A unit test gives a model fake input rows and checks the output rows. It needs no warehouse data, so it tests your *logic*. Put them in `models/marts/_unit_tests.yml`. (The zero-rate retirement test was added in PR-20.)

1. **Savings-goal waterfall.** Two goals share an account with 1,500 saved and a 500/month Savings budget; goal A needs 1,000 and goal B needs 1,000:
   ```yaml
     - name: dim_savings_goals_waterfall
       model: dim_savings_goals
       overrides:
         macros:
           today: "date('2026-10-15')"
       given:
         - input: ref('stg_google_sheets__savings_goals')
           rows:
             - {goal_id: 1, goal_name: 'A', goal_priority: 1}
             - {goal_id: 2, goal_name: 'B', goal_priority: 2}
         - input: ref('stg_google_sheets__savings_goals_details')
           rows:
             - {goal_detail_id: 1, goal_name: 'A', account_name: 'Savings Family', goal_amount: 1000}
             - {goal_detail_id: 2, goal_name: 'B', account_name: 'Savings Family', goal_amount: 1000}
         - input: ref('int_accounts')
           rows:
             - {account_name: 'Savings Family', current_balance: 1500}
         - input: ref('int_budget_latest_month')
           rows:
             - {budget_type: 'Savings', budget_month: '2026-10-01', budget_amount: 500}
       expect:
         rows:
           - {goal_name: 'A', goal_status: 'Achieved', goal_amount_saved: 1000, months_to_goal: 0}
           - {goal_name: 'B', goal_status: 'In Progress', goal_amount_saved: 500, months_to_goal: 2, funding_month: '2026-12-01'}
   ```
   B needs 500, which at 500/month is 1 month, plus the 1-month buffer = 2. Add a second test with **tied priorities** to prove the PR-15 window frame fix.

   **Commit now:** `test(marts): add unit tests for dim_savings_goals`

2. **Guilt-Free override** (`fct_monthly_paycheck_allocation`): give a Guilt-Free budget of 100 for a month and no matching transactions; expect `allocation_amount = 100` and `allocation_variance = 0`.

   **Commit now:** `test(marts): add unit test for guilt-free override in paycheck allocation`

3. **Future value** (`rpt_retirement_projection`): add a non-zero-rate case with a hand-calculated expected result.

   **Commit now:** `test(marts): add unit test for rpt_retirement_projection`

4. **XIRR** (`dim_investments`): one buy of -1,000 on 2025-10-09, a current value of 1,100, and `today` overridden to 2026-10-09 (365 days) should give 0.1 if the function uses a 365-day year. Check your function's convention first.

   **Commit now:** `test(marts): add unit test for dim_investments xirr`

5. The `overrides: macros:` syntax for replacing `today()` is what dbt's unit-test docs describe for macros; confirm the exact form for your version.
6. Run only unit tests with `dbt test --select test_type:unit`.

**PR title:** `test(marts): add unit tests for savings goals, allocation, retirement and XIRR`

**PR description** (paste into GitHub):

```markdown
## What changed
Adds unit tests for the savings-goal waterfall (including tied priorities), the Guilt-Free override, the retirement future value and the XIRR calculation. The `today()` macro is overridden wherever a test depends on the date.

## Why
These models hold the most logic, and unit tests check it without warehouse data.

## How I verified it
`dbt test --select test_type:unit` passes. I calculated each expected value by hand.

## Does data change?
No. Tests only.
```

**Checkpoint (end of phase 6):** `dbt build` is green. Open `chore(release): bump version to 2.0.0`, merge, then publish a GitHub release tagged `v2.0.0` the same way as v1.1.0.

### Phase 7 — CI and automation

#### PR-29 · `ci/dbt-cloud-ci`

dbt Cloud has CI jobs built in, so this replaces the GitHub Actions workflows from the earlier version of this plan. A CI job runs when a pull request is opened or updated, builds only the changed models (and everything downstream) into a temporary schema, and reports a pass/fail check on the PR. dbt's docs list CI jobs as available on all plans for GitHub; some extras (concurrent checks, smart cancellation) need a paid plan, so confirm in your account.

1. **Check the GitHub connection.** CI relies on webhooks from GitHub, so the project's repository must be connected through dbt Cloud's native GitHub integration (not a plain Git URL or deploy key). If it isn't, reconnect it under **Account settings → Projects → your project → Repository**.
2. **Create a CI environment.** **Orchestration → Environments → Create environment**: deployment type **General** (or Staging), the same BigQuery connection, and any dataset name (for example `dbt_ci`). dbt Labs recommends a dedicated environment for CI, separate from Production.
3. **Create the CI job.** On that environment's page choose **Create job → Continuous integration job** and set:
   - **Name:** `CI`.
   - **Triggered by pull requests:** on (the default). Leave *Run on draft pull request* off.
   - **Commands:** `dbt build --select state:modified+ --exclude package:dbt_project_evaluator`. This builds the modified models and everything downstream. For a project this small you could use a plain `dbt build --exclude package:dbt_project_evaluator` instead, which needs no deferral but rebuilds everything on every PR.
   - **Compare changes against an environment (deferral):** **Production**. This needs a successful run in Production, which your **Baseline: build main** job provides. Re-run it after each merge so the comparison state is current (a stale state makes CI select models that aren't in your PR).
   - **Linting:** on. It uses your `.sqlfluff` and checks the SQL files changed in the PR. Choose **Continue running on error** until the project is clean after PR-03, then switch to **Stop running on error**.
4. **Check how temporary schemas are cleaned up.** Each run builds into `dbt_cloud_pr_<job>_<pr>` (plus the layer suffix from PR-26), and dbt Cloud drops it when the PR is merged or closed. After the first PR merges, look in BigQuery to confirm the schema is gone. If it isn't, the `generate_schema_name` macro from PR-26 is producing names without the `dbt_cloud_pr_` prefix.
5. **Require the check on `main`.** On GitHub: **Settings → Branches → add a branch protection rule for `main` → Require status checks to pass**, and select the dbt Cloud check. It only appears in the list after the CI job has run once on a PR.
6. **Make `dbt_project_evaluator` pass, then blocking:**
   1. In the IDE run `dbt build --select package:dbt_project_evaluator`. Each finding is a failed test. Expect the warnings you saw in PR-11: `fct_model_naming_conventions`, `fct_model_directories`, `fct_source_directories`, `fct_model_fanout` and possibly `fct_missing_primary_key_tests`. `fct_sources_without_freshness` should already be clear after PR-12.
   2. Fix what's real. For your own naming (`rpt_` models, the `stg_<source>__<table>` pattern), configure the package's variables in `dbt_project.yml` (check the package docs for exact names), e.g.:
      ```yaml
      vars:
        dbt_project_evaluator:
          marts_prefixes: ['fct_', 'dim_', 'rpt_']
      ```
   3. For findings you accept, add them to the package's exceptions seed (`seeds/dbt_project_evaluator_exceptions.csv`; see the package docs for its columns), with a comment explaining why.
   4. When it passes, add a second command to the CI job: `dbt build --select package:dbt_project_evaluator`.

   **Commit now:** `chore(config): configure dbt_project_evaluator`

7. **PR template.** Create `.github/pull_request_template.md` with the four description headings from the routine in section 2 plus the review checklist from `STYLE_GUIDE.md` section 10. If the IDE won't let you create the hidden `.github` folder, add the file in GitHub's web editor (**Add file → Create new file**, name it `.github/pull_request_template.md`).

   **Commit now:** `chore: add pull request template`

8. **Public repository caution.** A CI job runs with your warehouse credentials. I couldn't confirm in dbt's docs how CI treats pull requests from forks, so if you accept outside contributions, check that before relying on CI. Never put credentials in the repo.

**PR title:** `chore(ci): configure dbt_project_evaluator and add pull request template`

**PR description** (paste into GitHub):

```markdown
## What changed
Adds a pull request template and configures `dbt_project_evaluator` (variables and the exceptions seed). The CI job itself is configured in dbt Cloud.

## Why
CI and the project evaluator keep every PR in line with the style guide.

## How I verified it
`dbt build --select package:dbt_project_evaluator` passes. The dbt Cloud CI job ran on this PR, and its check is required on `main`.

## Does data change?
No.
```

### Phase 8 — Documentation and portfolio polish

#### PR-30 · `docs/readme-and-adrs`

1. **Update the README.** A first version was published after PR-16 and says "planned" next to the pieces that didn't exist yet. As each PR lands, flip its line; in this PR check that nothing is left:

   | README text | Flip it when |
   |---|---|
   | Source freshness is "planned" | PR-12 |
   | Models build into one dataset | PR-26 (each layer gets its own dataset: update the architecture table, the run instructions and `generate_schema_name`) |
   | `retirement_projection` | PR-25 (it becomes `rpt_retirement_projection`) |
   | Contracts "planned" | PR-27 |
   | Unit tests "planned" | PR-28 |
   | CI "planned" | PR-29 |
   | Lineage image | when your custom graph is ready (`docs/images/lineage.png`) |
   | Link to `docs/decisions/` | this PR, once the ADRs exist |
   | Link to the data generator script | Task G, step 9 |

   The sections stay in this order: what the project answers; architecture and lineage; data sources and the data feed; requirements; how to run; conventions; testing and CI; how to add a new budget year; decisions.

   **Commit now:** `docs: update README for the finished project`

2. **ADRs** (short decision records) in `docs/decisions/`, one file each. Use this template:
   ```
   # 0001. <title>
   Status: accepted · Date: 2026-10-09

   ## Context
   What problem or choice came up?

   ## Decision
   What did you choose?

   ## Consequences
   What does that make easier or harder?
   ```
   Suggested first five: (1) readable surrogate keys through `slug_key`; (2) budgets unpivoted per year and combined in one stable model; (3) Guilt-Free spending is treated as auto-allocated at its budget, and unspent amounts carry over across years; (4) "latest month" is driven by the latest transaction, not the calendar; (5) derived metrics are kept in `dim_savings_goals` and `dim_investments` as a documented exception.

   **Commit now:** `docs: add architecture decision records`

3. Link the style guide and ADRs from the README.

**PR title:** `docs: update README and add architecture decision records`

**PR description** (paste into GitHub):

```markdown
## What changed
Updates the README now that the planned pieces exist (layer datasets, contracts, unit tests, CI, lineage image) and adds the first ADRs under `docs/decisions/`.

## Why
A reader should understand the project and its decisions without asking me.

## How I verified it
The links and image render on GitHub, and the 'How to run' steps work from a clean checkout.

## Does data change?
No.
```

---

## 5. Tracking

- Keep this file as a checklist; tick items as PRs merge. The status table at the top shows where you are.
- Anything you decide to skip: leave a one-line note under the PR saying why, so the style guide and the code don't silently disagree.
- Remaining backlog items from the style guide appendix are all covered above except the optional ones (tags/meta values, exposures content), which depend on how you use the project.

### Definition of done

- [ ] `main` builds green (`dbt build`), including unit tests and the project evaluator
- [ ] No `severity: warn` tests left except documented monitors
- [ ] The dbt Cloud CI check is required on `main` and passes on a fresh PR (build, lint, project evaluator)
- [ ] GitHub releases `v1.1.0` and `v2.0.0` exist
- [ ] Source freshness is configured and passes, and the data generator's daily trigger is running
- [ ] `STYLE_GUIDE.md` and the code agree (any decision you skipped is noted in the plan)
