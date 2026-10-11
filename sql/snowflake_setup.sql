-- Step 2 (Load to the warehouse): S3 -> Snowflake RAW tables.
-- Run by scripts/load_to_snowflake.py, which fills in the {{ placeholders }} from .env.

-- Compute: a small warehouse that suspends itself after 60 seconds idle (saves credits).
CREATE WAREHOUSE IF NOT EXISTS {{warehouse}}
  WAREHOUSE_SIZE = 'XSMALL' AUTO_SUSPEND = 60 AUTO_RESUME = TRUE INITIALLY_SUSPENDED = TRUE;
USE WAREHOUSE {{warehouse}};

CREATE DATABASE IF NOT EXISTS {{database}};
CREATE SCHEMA IF NOT EXISTS {{database}}.RAW;
USE SCHEMA {{database}}.RAW;

-- How to read the CSVs. PARSE_HEADER lets Snowflake use the header row as column names.
-- FIELD_OPTIONALLY_ENCLOSED_BY handles review comments that contain commas and new lines.
CREATE OR REPLACE FILE FORMAT csv_format
  TYPE = CSV
  PARSE_HEADER = TRUE
  FIELD_OPTIONALLY_ENCLOSED_BY = '"'
  NULL_IF = ('', 'NULL')
  EMPTY_FIELD_AS_NULL = TRUE
  ERROR_ON_COLUMN_COUNT_MISMATCH = FALSE;

-- External stage: a named pointer to the S3 folder.
CREATE OR REPLACE STAGE airbnb_s3_stage
  URL = 's3://{{bucket}}/airbnb/raw/'
  CREDENTIALS = (AWS_KEY_ID = '{{aws_key_id}}' AWS_SECRET_KEY = '{{aws_secret_key}}')
  FILE_FORMAT = csv_format;
