"""Extract + Load: download MovieLens and land the raw CSVs in DuckDB, untouched.

All transformation happens later in dbt (ELT). The raw schema is rebuilt on every
run, so the load is idempotent.
"""
from __future__ import annotations

import io
import sys
import urllib.request
import zipfile
from pathlib import Path

import duckdb

DATASET_URL = "https://files.grouplens.org/datasets/movielens/ml-latest-small.zip"
ROOT = Path(__file__).resolve().parent.parent
DATA_DIR = ROOT / "data" / "raw"
DB_PATH = ROOT / "data" / "netflix.duckdb"
TABLES = ("movies", "ratings", "tags", "links")


def download() -> None:
    if all((DATA_DIR / f"{name}.csv").exists() for name in TABLES):
        print(f"Raw CSVs already present in {DATA_DIR}")
        return
    print(f"Downloading {DATASET_URL}")
    with urllib.request.urlopen(DATASET_URL, timeout=60) as response:
        archive = zipfile.ZipFile(io.BytesIO(response.read()))
    DATA_DIR.mkdir(parents=True, exist_ok=True)
    for name in TABLES:
        member = f"ml-latest-small/{name}.csv"
        (DATA_DIR / f"{name}.csv").write_bytes(archive.read(member))
    print(f"Extracted {len(TABLES)} files to {DATA_DIR}")


def load() -> None:
    con = duckdb.connect(str(DB_PATH))
    con.execute("create schema if not exists raw")
    for name in TABLES:
        path = (DATA_DIR / f"{name}.csv").as_posix()
        # all_varchar keeps the raw layer exactly as delivered; dbt staging does the casting.
        con.execute(
            f"create or replace table raw.{name} as "
            f"select * from read_csv('{path}', header = true, all_varchar = true)"
        )
        rows = con.execute(f"select count(*) from raw.{name}").fetchone()[0]
        print(f"raw.{name}: {rows:,} rows")
    con.close()


if __name__ == "__main__":
    try:
        download()
        load()
    except Exception as exc:  # surface a clean message in CI logs
        print(f"Load failed: {exc}", file=sys.stderr)
        raise
