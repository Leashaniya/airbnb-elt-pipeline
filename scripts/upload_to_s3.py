"""Step 1 (Extract + Load to the lake): upload the raw Kaggle CSVs to S3.

Each file goes under its own prefix, so Snowflake can load one table per folder:
    s3://<bucket>/airbnb/raw/listings/listings.csv
    s3://<bucket>/airbnb/raw/reviews/reviews.csv
    s3://<bucket>/airbnb/raw/calendar/calendar.csv
"""

import os
from pathlib import Path

import boto3
from botocore.exceptions import ClientError
from dotenv import load_dotenv

PROJECT_ROOT = Path(__file__).resolve().parent.parent
RAW_DIR = PROJECT_ROOT / "data" / "raw"
TABLES = ["listings", "reviews", "calendar"]


def ensure_bucket(s3, bucket: str, region: str) -> None:
    try:
        s3.head_bucket(Bucket=bucket)
        print(f"Bucket exists: s3://{bucket}")
    except ClientError:
        config = {} if region == "us-east-1" else {"CreateBucketConfiguration": {"LocationConstraint": region}}
        s3.create_bucket(Bucket=bucket, **config)
        print(f"Created bucket: s3://{bucket}")


def main() -> None:
    load_dotenv(PROJECT_ROOT / ".env")
    bucket = os.environ["S3_BUCKET"]
    region = os.environ.get("AWS_REGION", "us-east-1")
    s3 = boto3.client("s3", region_name=region)  # credentials come from the AWS_* env vars

    ensure_bucket(s3, bucket, region)
    for table in TABLES:
        path = RAW_DIR / f"{table}.csv"
        if not path.exists():
            raise FileNotFoundError(f"Missing {path}. Download the Kaggle dataset first.")
        key = f"airbnb/raw/{table}/{table}.csv"
        s3.upload_file(str(path), bucket, key)
        print(f"Uploaded {path.name} ({path.stat().st_size / 1e6:.1f} MB) -> s3://{bucket}/{key}")


if __name__ == "__main__":
    main()
