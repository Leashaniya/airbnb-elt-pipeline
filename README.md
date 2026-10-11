# 🏠 Airbnb End-to-End Data Engineering Pipeline

A cloud-native **ELT** pipeline: raw Airbnb data is loaded into **AWS S3**, staged and copied into
**Snowflake**, then transformed with **dbt** through staging, intermediate and mart layers into a
dimensional model, with dbt tests for data quality.

**Data:** [Seattle Airbnb Open Data](https://www.kaggle.com/datasets/airbnb/seattle) (Kaggle, published by Airbnb):
3,818 listings from 2,751 hosts, 84,849 reviews (2009–2016) and 1.39M daily calendar rows (2016).

---

## 🗺️ How it works

```
Kaggle CSVs
   │  ① scripts/upload_to_s3.py
   ▼
AWS S3   s3://<bucket>/airbnb/raw/{listings,reviews,calendar}/
   │  ② scripts/load_to_snowflake.py   (external stage + COPY INTO)
   ▼
Snowflake RAW schema   every column as text, plus _SOURCE_FILE and _LOADED_AT
   │  ③ dbt build
   ▼
STAGING (views)        stg_listings, stg_hosts, stg_reviews, stg_calendar
   ▼
INTERMEDIATE (ephemeral)   int_listing_review_stats, int_listing_availability_stats
   ▼
MARTS (tables)         dim_hosts, dim_listings, fct_reviews (incremental), fct_listing_calendar
```

| Layer | What happens | Why |
|---|---|---|
| **S3** | Raw files stored as they came | Cheap, durable copy of the source; can reload anytime |
| **RAW** | `COPY INTO` from an external stage. All columns `VARCHAR` | ELT: load first, transform later. A bad value never blocks the load. `COPY` skips files it has already loaded |
| **Staging** | Rename, cast types, `'$1,250.00'` → `1250.00`, `'t'/'f'` → boolean, one row per host | One clean model per source, reused by everything downstream |
| **Intermediate** | Review stats and occupancy per listing | Business logic kept separate from the final tables |
| **Marts** | Star schema: 2 dimensions + 2 facts | What analysts and BI tools query |

## 📊 Results

| Step | Result |
|---|---|
| S3 upload | 3 files, 90 MB, to `s3://<bucket>/airbnb/raw/` (ap-south-1) |
| COPY INTO RAW | 3,818 listings · 84,849 reviews · 1,393,570 calendar rows, all rows loaded, 0 errors |
| `dbt build` | 4 views, 3 tables, 1 incremental model, 31 tests: **38 passed, 1 warning, 0 errors** in about 6 s |
| Incremental re-run | `fct_reviews` added **0** rows (nothing newer than the latest review) |

**What the marts show:**
- Entire homes are 67% of listings, at an average of $156/night vs $75 for a private room
- Queen Anne has the highest average occupancy (38%) and price ($157)
- Superhosts average a 97.4 rating vs 93.7 for other hosts

## ⭐ Dimensional model

```
             dim_hosts
                 │ host_id
             dim_listings ── occupancy_rate, total_reviews, price…
            ╱            ╲ listing_id
   fct_reviews        fct_listing_calendar
 (one row per review)  (one row per listing per day)
```

## ✅ Data quality (dbt tests)

- `unique` / `not_null` on every primary key
- `relationships`: every review and calendar row points to a real listing; every listing to a real host
- `accepted_values` on `room_type`
- Custom generic tests: `positive_value` (prices), `accepted_range_0_1` (occupancy rate),
  `unique_combination` (listing + date in the calendar)
- Singular test `assert_review_not_before_host_joined`: flags reviews dated before the host joined.
  The source has 87 of these, so it is set to **warn** rather than fail

## 📂 Project structure

```
airbnb-elt-pipeline/
├── scripts/
│   ├── upload_to_s3.py          step 1: CSVs -> S3
│   └── load_to_snowflake.py     step 2: S3 -> Snowflake RAW
├── sql/snowflake_setup.sql      warehouse, database, file format, external stage
├── airbnb_dbt/                  step 3: dbt project
│   ├── models/staging/          sources + stg_ models + tests
│   ├── models/intermediate/     int_ models
│   ├── models/marts/            dim_ and fct_ models + tests
│   ├── macros/                  clean_money, to_bool, schema naming
│   └── tests/                   custom generic + singular tests
├── run.sh                       runs all three steps
└── .env.example                 settings template (real .env is never committed)
```

## ▶️ How to run

1. Download the dataset from Kaggle and unzip `listings.csv`, `reviews.csv`, `calendar.csv` into `data/raw/`
2. `cp .env.example .env` and fill in your AWS and Snowflake values
3. Python 3.10–3.13 (dbt-snowflake doesn't support 3.14 yet):
   ```bash
   python3.13 -m venv .venv
   .venv/bin/pip install -r requirements.txt
   ```
4. `./run.sh`

## 🔧 What I'd improve next

- Use a Snowflake **storage integration** (IAM role) instead of access keys on the stage
- **Snapshots** (SCD Type 2) on listings to track price changes across monthly scrapes
- Orchestrate the three steps with Airflow, and run `dbt build` in CI on every pull request
- Snowpipe or a scheduled task to load new files as they land in S3
