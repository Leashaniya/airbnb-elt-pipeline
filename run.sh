#!/usr/bin/env bash
# Runs the whole pipeline: S3 upload -> Snowflake load -> dbt build.
# Usage: ./run.sh            (all steps)
#        ./run.sh dbt         (dbt only)
set -euo pipefail
cd "$(dirname "$0")"

if [[ ! -f .env ]]; then
  echo "Missing .env - copy .env.example to .env and fill in your values." >&2
  exit 1
fi
set -a; source .env; set +a
source .venv/bin/activate

if [[ "${1:-all}" == "all" ]]; then
  echo "== Step 1: upload raw CSVs to S3"
  python scripts/upload_to_s3.py
  echo "== Step 2: load S3 files into Snowflake RAW tables"
  python scripts/load_to_snowflake.py
fi

echo "== Step 3: dbt build (models + tests)"
cd airbnb_dbt
dbt build --profiles-dir .
