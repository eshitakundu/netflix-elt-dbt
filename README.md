# Netflix Data Analysis — dbt + Snowflake + AWS S3

An end-to-end data engineering project that ingests movie data from AWS S3 into Snowflake and transforms it using dbt. Demonstrates a production-style ELT pipeline with layered data modelling, testing, documentation, and version-controlled transformations.

---

## Tech Stack

| Layer | Tool |
|---|---|
| Raw Storage | AWS S3 |
| Data Warehouse | Snowflake |
| Transformation | dbt (data build tool) |
| Version Control | Git + GitHub |
| Language | SQL, YAML |

---

## Architecture

```
AWS S3 (raw CSV files)
    │
    ▼
Snowflake RAW schema        ← source data, never modified
    │
    ▼
dbt STAGING models          ← light cleaning, renaming, type casting
    │
    ▼
dbt MARTS models            ← business-level aggregations and dimensions
```

This follows the **ELT pattern** — data is loaded into Snowflake first in raw form, and all transformation logic runs inside the warehouse via dbt.

---

## Project Structure

```
netflix-dbt/
├── models/
│   ├── staging/
│   └── marts/
├── seeds/
├── snapshots/
├── tests/
├── macros/
├── analyses/
├── dbt_project.yml
└── README.md
```

---

## dbt Concepts Covered

- **Models** — SQL SELECT statements materialised as tables or views
- **Sources** — declarations of raw tables dbt doesn't own
- **Seeds** — static reference data loaded from CSV
- **Snapshots** — SCD Type 2 change tracking
- **Tests** — `not_null`, `unique`, `accepted_values`, relationships
- **Documentation** — auto-generated data catalogue from `schema.yml`
- **Macros** — reusable Jinja/SQL logic
- **Analysis** — exploratory SQL tracked in version control

---

## Getting Started

### Prerequisites

- Snowflake account
- AWS S3 bucket with source data
- dbt Core: `pip install dbt-snowflake`
- Python 3.8+

### Run

```bash
dbt debug        # test Snowflake connection
dbt run          # execute all models
dbt test         # run data tests
dbt docs generate && dbt docs serve   # view documentation
```

---

## Dataset

[MovieLens 20M Dataset](https://grouplens.org/datasets/movielens/20m/) — GroupLens Research

---
