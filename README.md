# AI Career Threat Index Analysis

A PostgreSQL project exploring how an AI career-threat dataset describes automation risk, agentic AI exposure, salary ranges and trends, job categories, and recommended defense skills. The SQL script prepares and queries an existing PostgreSQL table, then builds a salary comparison table for further analysis.

> **Interpretation:** The results describe the supplied dataset. The files do not identify its publisher, methodology, or provenance, so this project does not establish that the scores are independently validated measures of real-world job displacement.

## Project overview

The analysis uses a CSV of occupational records and SQL queries to examine questions such as:

- Which job categories contain the most roles labeled high or very high risk?
- How do AI risk labels and agentic risk labels compare across occupations?
- How do those labels vary by salary range and reported salary trend?
- Which roles have high tool-maturity, adoption, or task-automation scores?
- What defense skills and occupational insights are recorded for higher-risk roles?
- For the subset with quarterly scores, how do the supplied 2025 and 2026 score averages compare?
- Which SOC codes appear with more than one AI risk label?

## Dataset

The supplied `ai-career-threat-index.csv` contains **300 rows and 26 columns**. Each row represents a role. The file has no accompanying source or methodology documentation in the supplied materials.

| Fields | Description based on the column names and values |
|---|---|
| `slug`, `title`, `category`, `soc_code`, `tier` | Role identifiers and occupational grouping fields |
| `score`, `risk_level`, `agentic_risk` | Overall score and categorical AI / agentic risk labels |
| `salary_low_usd`, `salary_high_usd`, `salary_trend` | Salary range in USD and a trend label |
| `tasks_at_risk_count`, `tasks_growing_count` | Counts of tasks described as at risk or growing |
| `defense_skill_1`–`defense_skill_3`, `insight` | Suggested skills and a narrative note for the role |
| `score_q1_2025`, `score_q3_2025`, `score_q1_2026`–`score_q3_2026` | Quarterly score fields; many values are blank |
| `sub_task_automation`, `sub_tool_maturity`, `sub_adoption`, `sub_agentic_exposure` | Component score fields |

## Findings visible in the supplied data

These are descriptive summaries of the CSV, not independently validated conclusions about the labor market:

- Across the 300 roles, 56 are labeled `High` or `Very High` for AI risk. `Administrative & Operations` has the largest count (15 of 20 roles in that category); `Business & Finance` and `Marketing & Sales` have 9 each. `Education` has one such role.
- 44 roles are labeled `High` or `Very High` for both `risk_level` and `agentic_risk`.
- The script’s salary-band query groups roles by the midpoint of the low and high salary estimates. The dataset has 160 roles in the $50,001–$100,000 midpoint band, with 38 labeled high/very high AI risk and 36 high/very high agentic risk. These are counts rather than rates and are affected by the different band sizes.
- For salary trends, 24 of 36 roles labeled `declining` are high/very high AI risk, compared with 13 of 152 roles labeled `stable`. This is an association in these records; it does not show that salary trends cause or predict AI risk.
- All 76 roles with values in the quarterly score fields have a higher 2026 mean than 2025 mean under the script’s averaging method. That method averages Q1 and Q3 for 2025 and Q1, Q2, and Q3 for 2026. The other 224 roles do not have those earlier quarterly values, so this comparison covers only a subset.

## Analysis workflow

1. Create a PostgreSQL table named `public.ai_career_threat_index` with columns corresponding to the CSV headers.
2. Load the CSV into that table, treating blank quarterly score values as `NULL`.
3. Run `ai_career_threat_index_analysis.sql` in a PostgreSQL client.
4. Review the query outputs. The script also creates `salary_comparison_table` using the midpoint of each role’s salary range.

The SQL includes a sample-row query, duplicate-slug check, category and risk summaries, risk filters, salary-band and salary-trend summaries, score comparisons, defense-skill inspection, and analysis of SOC codes with multiple risk labels.

## How to run

Requirements: PostgreSQL and a client such as `psql` or pgAdmin.

1. Create a database and connect to it.
2. Create the table using the CSV’s column names and suitable numeric/text types. For example:

```sql
CREATE TABLE public.ai_career_threat_index (
    slug text,
    title text,
    category text,
    score integer,
    risk_level text,
    salary_low_usd integer,
    salary_high_usd integer,
    salary_trend text,
    tasks_at_risk_count integer,
    tasks_growing_count integer,
    defense_skill_1 text,
    defense_skill_2 text,
    defense_skill_3 text,
    insight text,
    score_q1_2025 integer,
    score_q3_2025 integer,
    score_q1_2026 integer,
    score_q2_2026 integer,
    score_q3_2026 integer,
    soc_code text,
    tier integer,
    sub_task_automation integer,
    sub_tool_maturity integer,
    sub_adoption integer,
    sub_agentic_exposure integer,
    agentic_risk text
);
```

3. Load the CSV. With `psql`, use a path that exists on your computer:

```text
\copy public.ai_career_threat_index FROM '/path/to/ai-career-threat-index.csv' WITH (FORMAT csv, HEADER true, NULL '')
```

4. Open `ai_career_threat_index_analysis.sql` and execute it while connected to that database. The first statement truncates the target table, so run the script only after loading the data and only when you are comfortable clearing and reloading that table. The `CREATE TABLE salary_comparison_table` statement will also need the existing derived table dropped or renamed before rerunning the script.

## SQL skills demonstrated

- Loading and preparing tabular data for analysis
- Column type changes with `ALTER TABLE`
- Grouping, filtering, sorting, and duplicate checks
- Combining conditions with `AND` and `OR`
- Common table expressions (CTEs) and `CASE` expressions
- Conditional aggregation with `FILTER`
- Calculated columns, averages, differences, and percentage changes
- Creating a derived table with `CREATE TABLE AS`
- Comparing labels and records across categories, salary bands, time fields, and SOC codes

## Limitations and SQL notes

- **Risk scores are not necessarily probabilities.** The dataset does not document what its scores mean, how they were produced, or whether they are calibrated. A score or label should not be read as the probability that a job will disappear.
- **Correlation is not causation.** Grouping risk labels alongside salaries or salary trends does not establish a causal relationship.
- **The data source and collection method are unspecified** in the supplied files. Treat narrative insights and labels as dataset content, not verified forecasts.
- **Quarterly comparisons use only 76 of 300 roles** with all five required score fields populated. They also compare two quarters in 2025 against three in 2026, as the SQL comments describe.
- **One query has an `AND`/`OR` precedence issue.** The “sub-task automation > 60” query mixes `AND` and `OR` without parentheses. PostgreSQL evaluates `AND` before `OR`, so some returned rows may not satisfy the intended combination of automation score and risk labels. Add explicit parentheses around the intended risk conditions before treating that result as a reliable filtered list.
- **The script changes and clears database state.** Its initial `TRUNCATE` deletes all rows in the target table, and its salary comparison table creation can fail if that table already exists. Use a disposable database or adjust the script for repeatable runs.

## Suggested repository structure

```text
.
├── README.md
├── data/
│   └── ai-career-threat-index.csv
└── sql/
    └── ai_career_threat_index_analysis.sql
```

Keep the CSV’s source and license information with the data if you can establish them. If the dataset has redistribution restrictions, provide instructions for obtaining it instead of committing a copy.

## Data Source

This project uses the **AI Career Threat Index** dataset (v2026.3), created by
MeritForge AI and released under the MIT License.

Copyright (c) 2026 Jeff Otterson / MeritForge AI. The original license text is
included in [`data/LICENSE-ai-career-threat-index.txt`](data/LICENSE-ai-career-threat-index.txt).

**Citation:**

> The MeritForge Team (2026). AI Career Threat Index v2026.3.
> https://github.com/Jott2121/ai-career-threat-index
> (DOI: 10.5281/zenodo.21227026)

The dataset is used here for educational and portfolio purposes. All analysis and
queries in this repository are my own work and are not
endorsed by the dataset authors.
