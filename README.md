# Netflix-style ELT with dbt + DuckDB

[![dbt build](https://github.com/eshitakundu/netflix-elt-dbt/actions/workflows/dbt.yml/badge.svg)](https://github.com/eshitakundu/netflix-elt-dbt/actions/workflows/dbt.yml)

An end-to-end ELT pipeline over the MovieLens ratings dataset: a Python script extracts and loads the raw CSVs into DuckDB untouched, then dbt transforms them into tested staging views and analytics marts. The whole thing runs locally in about 10 seconds and on every push in GitHub Actions.

**Timeline:** started May 2026 as a Snowflake + S3 plan · rebuilt October 2026 on dbt + DuckDB with tests and CI. It now runs on DuckDB so anyone can clone and run it with no cloud account, and the dbt models stay warehouse-agnostic SQL.

## Architecture

```
MovieLens zip (GroupLens)
        |  scripts/load_raw.py  (extract + load, idempotent)
        v
DuckDB  raw.*          movies, ratings, tags, links  (all text, exactly as delivered)
        |  dbt
        v
staging.*  (views)     stg_movies, stg_ratings, stg_tags, stg_links
        |                cast types, parse year out of title, split genres, normalise tags
        v
marts.*    (tables)    fct_ratings, dim_movies, dim_users,
                       bridge_movie_genres, mart_genre_performance
reference.*  (seed)    genre_groups
```

## What's in it

| Piece | Where | Notes |
|---|---|---|
| Extract + load | `scripts/load_raw.py` | Downloads `ml-latest-small` and lands 4 tables in `raw`. Re-runnable. |
| Sources | `models/staging/_sources.yml` | Declares the raw tables with key tests. |
| Staging | `models/staging/` | One view per source. Year parsed out of `"Heat (1995)"`, genres split into a list. |
| Marts | `models/marts/` | Star schema: `fct_ratings` + `dim_movies` + `dim_users`, a movie-to-genre bridge, and a genre performance mart. |
| Seed | `seeds/genre_groups.csv` | Maps 19 genres to reporting groups. A new genre in the source fails a test until it's mapped. |
| Macros | `macros/` | `decade_of()` for decade buckets; `generate_schema_name` so schemas are `staging`/`marts`, not `main_staging`. |
| Tests | `*.yml` + `tests/` | 42 tests: unique, not_null, relationships, accepted_values, plus 2 custom ones (see below). |
| Analysis | `analyses/top_movies_by_decade.sql` | Top 5 per decade by weighted rating. |
| CI | `.github/workflows/dbt.yml` | Load + `dbt build` + docs on every push and PR. |

### Modelling decisions

- **Weighted rating.** `dim_movies.weighted_rating` is a Bayesian average: `(v/(v+m))·R + (m/(v+m))·C`, where `v` is the movie's rating count, `R` its average, `C` the global mean and `m` = 10 (`var('min_votes_for_weighting')`). A film with one 5-star vote no longer beats one with 300 ratings averaging 4.4.
- **Genre bridge.** Movies have several genres, so genre metrics go through `bridge_movie_genres` instead of exploding the fact table. A custom test (`assert_genre_ratings_reconcile`) checks that the genre mart counts each rating exactly once per genre.
- **Raw stays raw.** The load step reads every column as text. All casting lives in staging, so a type problem fails a dbt test with a clear name instead of breaking the load.

## Results

From the current dataset (100,836 ratings, 9,742 movies, 610 users):

| Top movies by weighted rating (50+ ratings) | Ratings | Avg | Weighted |
|---|---:|---:|---:|
| The Shawshank Redemption (1994) | 317 | 4.43 | 4.401 |
| The Godfather (1972) | 192 | 4.29 | 4.250 |
| Fight Club (1999) | 218 | 4.27 | 4.239 |

| Genre | Movies | Ratings | Avg rating | Share rated 4+ |
|---|---:|---:|---:|---:|
| Film-Noir | 87 | 870 | 3.92 | 67.6% |
| War | 382 | 4,859 | 3.81 | 61.6% |
| Documentary | 440 | 1,219 | 3.80 | 59.8% |
| Drama | 4,361 | 41,928 | 3.66 | 54.7% |

Niche genres rate highest: fewer people watch them, and the ones who do chose to. Drama has 48x the ratings of Film-Noir but a lower average.

Data quality notes surfaced by the models: 13 titles have no release year, and 18 movies have no ratings (kept in `dim_movies` with `rating_count = 0`).

## Run it

```bash
python -m venv .venv
source .venv/bin/activate        # Windows: .venv\Scripts\activate
pip install -r requirements.txt

python scripts/load_raw.py       # extract + load into data/netflix.duckdb
dbt build --profiles-dir .       # run all models, seeds and 42 tests
dbt docs generate --profiles-dir . && dbt docs serve --profiles-dir .   # lineage graph + catalogue
```

To query the marts directly:

```bash
python -c "import duckdb; print(duckdb.connect('data/netflix.duckdb').sql('select * from marts.mart_genre_performance order by avg_rating desc'))"
```

## Stack

Python · DuckDB · dbt Core (dbt-duckdb) · SQL + Jinja · GitHub Actions

## Dataset

[MovieLens Latest Small](https://grouplens.org/datasets/movielens/latest/) by GroupLens Research, downloaded at run time and not redistributed in this repo. F. Maxwell Harper and Joseph A. Konstan. 2015. *The MovieLens Datasets: History and Context.* ACM TiiS 5, 4.
