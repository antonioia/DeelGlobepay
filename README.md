# Deel Analytics Engineer Challenge

DBT project for Globepay card payments built with dbt Core on BigQuery.

## Deliverables

| Part | Document |
|---|---|
| **Part 1**: data exploration, model architecture, lineage graphs, tips on macros, data validation and documentation | [`docs/ingestion_and_modeling.md`](docs/ingestion_and_modeling.md) |
| **Part 2**: production model, answers to the three questions, code and charts for the Data Analyst | [`analyses/questions/insights.md`](analyses/questions/insights.md) |
| **Presentation**: slides covering Part 1 and Part 2 | [`docs/Deel - Antonio Iannacci - Globepay AE exercise.pdf`](<docs/Deel - Antonio Iannacci - Globepay AE exercise.pdf>) |

## Project structure

```
models/
  staging/globepay/     sources + stg_globepay__acceptances, stg_globepay__chargebacks (views)
  marts/finance/        fct_globepay_transactions (table): the model the analyst queries
analyses/
  exploration/          11 profiling queries on the raw sources (Part 1)
  questions/            queries answering the 3 analyst questions (plus by-country and crossing-date breakdowns), with charts (Part 2)
docs/                   Part 1 document, lineage screenshots and the presentation (PDF)
```

## BigQuery datasets

| Layer | Managed by | Dataset |
|---|---|---|
| Raw | `bq load` + dbt `source` | `raw_globepay` |
| Staging | dbt (views) | `analytics_staging` |
| Marts | dbt (table) | `analytics_finance` |

Single environment (target `prod`, dataset `analytics`). Dataset names follow dbt's default convention
`<target dataset>_<custom schema>`.

## Reproducibility

The project runs against a personal GCP project. To run it elsewhere, change `project` in `profiles.yml` and in `models/staging/globepay/_globepay__sources.yml`, then load the CSVs as shown below.

## GCP and Environment Setup

```bash
# 1. Google authentication (Application Default Credentials)
gcloud auth application-default login
gcloud auth application-default set-quota-project deel-globepay

# 2. Python environment + dbt Core
uv venv .venv --python 3.11
uv pip install --python .venv/bin/python -r requirements.txt
```

## Loading the raw data using the terminal

All columns are loaded as `STRING` since types are cast in the dbt staging models.
These commands are executed directly from the local machine terminal configured to execute commands through the GCP client with the Google Cloud SDK.

```bash
D="../task_data"   # folder with the exercise CSV files
bq --location=EU mk --dataset deel-globepay:raw_globepay
bq --location=EU load --source_format=CSV --skip_leading_rows=1 --replace \
  deel-globepay:raw_globepay.acceptance_report "$D/Globepay Acceptance Report - Globepay Acceptance Report (2).csv" \
  external_ref:STRING,status:STRING,source:STRING,ref:STRING,date_time:STRING,state:STRING,cvv_provided:STRING,amount:STRING,country:STRING,currency:STRING,rates:STRING
bq --location=EU load --source_format=CSV --skip_leading_rows=1 --replace \
  deel-globepay:raw_globepay.chargeback_report "$D/Globepay Chargeback Report - Globepay Chargeback Report.csv" \
  external_ref:STRING,status:STRING,source:STRING,chargeback:STRING
```

## Running

In order to run the project you just need to activate the virtual environment and run the following commands:

```bash
source .venv/bin/activate
export DBT_PROFILES_DIR=.
dbt build                                                    # models + 30 data tests
dbt show --select 01_acceptance_rate_over_time --limit 100   # run an analysis
dbt docs generate && dbt docs serve                          # docs and lineage graph
```

`dbt build` ends with **1 expected warning** (`PASS=32 WARN=1 ERROR=0`): the `amount_local >= 0` test on
`stg_globepay__acceptances` flags an accepted transaction of -23.78 GBP.
The row is kept as reported by Globepay and the test is set to `warn` on purpose
(see [Part 1, section 1.2](docs/ingestion_and_modeling.md#12-findings), check 08).
