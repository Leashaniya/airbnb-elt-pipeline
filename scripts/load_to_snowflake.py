"""Step 2 (Load to the warehouse): create the Snowflake objects and COPY the S3 files into RAW tables.

RAW tables keep every column as text, exactly as it arrived (ELT: load first,
transform later in dbt). Each table gets two metadata columns: the source file
and the load time.

COPY INTO remembers which files it already loaded, so re-running this script
doesn't load the same file twice.
"""

import os
from pathlib import Path

import snowflake.connector
from dotenv import load_dotenv

PROJECT_ROOT = Path(__file__).resolve().parent.parent
TABLES = ["listings", "reviews", "calendar"]


def connect():
    return snowflake.connector.connect(
        account=os.environ["SNOWFLAKE_ACCOUNT"],
        user=os.environ["SNOWFLAKE_USER"],
        password=os.environ["SNOWFLAKE_PASSWORD"],
        role=os.environ.get("SNOWFLAKE_ROLE", "ACCOUNTADMIN"),
    )


def setup_sql() -> list[str]:
    sql = (PROJECT_ROOT / "sql" / "snowflake_setup.sql").read_text()
    values = {
        "warehouse": os.environ.get("SNOWFLAKE_WAREHOUSE", "AIRBNB_WH"),
        "database": os.environ.get("SNOWFLAKE_DATABASE", "AIRBNB"),
        "bucket": os.environ["S3_BUCKET"],
        "aws_key_id": os.environ["AWS_ACCESS_KEY_ID"],
        "aws_secret_key": os.environ["AWS_SECRET_ACCESS_KEY"],
    }
    for name, value in values.items():
        sql = sql.replace("{{" + name + "}}", value)
    lines = [line for line in sql.splitlines() if not line.strip().startswith("--")]
    return [stmt.strip() for stmt in "\n".join(lines).split(";") if stmt.strip()]


def create_raw_table(cur, table: str) -> None:
    """Create the RAW table from the CSV header, with every column as VARCHAR."""
    cur.execute(f"""
        CREATE TABLE IF NOT EXISTS {table} USING TEMPLATE (
            SELECT ARRAY_AGG(OBJECT_CONSTRUCT(
                       'COLUMN_NAME', UPPER(COLUMN_NAME), 'TYPE', 'VARCHAR', 'NULLABLE', TRUE))
                   WITHIN GROUP (ORDER BY ORDER_ID)
            FROM TABLE(INFER_SCHEMA(LOCATION => '@airbnb_s3_stage/{table}/',
                                    FILE_FORMAT => 'csv_format'))
        )
    """)
    cur.execute(f"ALTER TABLE {table} ADD COLUMN IF NOT EXISTS _SOURCE_FILE VARCHAR")
    cur.execute(f"ALTER TABLE {table} ADD COLUMN IF NOT EXISTS _LOADED_AT TIMESTAMP_LTZ")


def copy_into(cur, table: str) -> None:
    cur.execute(f"""
        COPY INTO {table}
        FROM @airbnb_s3_stage/{table}/
        MATCH_BY_COLUMN_NAME = CASE_INSENSITIVE
        INCLUDE_METADATA = (_SOURCE_FILE = METADATA$FILENAME, _LOADED_AT = METADATA$START_SCAN_TIME)
        ON_ERROR = ABORT_STATEMENT
    """)
    for row in cur.fetchall():
        print(f"  {table}: {row}")
    count = cur.execute(f"SELECT COUNT(*) FROM {table}").fetchone()[0]
    print(f"RAW.{table.upper()} now has {count:,} rows")


def main() -> None:
    load_dotenv(PROJECT_ROOT / ".env")
    conn = connect()
    try:
        cur = conn.cursor()
        for stmt in setup_sql():
            cur.execute(stmt)
        print("Created warehouse, database, RAW schema, file format and S3 stage")
        for table in TABLES:
            create_raw_table(cur, table)
            copy_into(cur, table)
    finally:
        conn.close()


if __name__ == "__main__":
    main()
