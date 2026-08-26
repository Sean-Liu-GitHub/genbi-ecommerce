import os
from google.cloud import bigquery
from google.oauth2 import service_account

MAX_BYTES = int(os.environ.get("MAX_QUERY_BYTES", 10_000_000_000))

def client(creds_path: str | None = None) -> bigquery.Client:
    path = creds_path or os.environ["GOOGLE_APPLICATION_CREDENTIALS"]
    creds = service_account.Credentials.from_service_account_file(path)
    return bigquery.Client(credentials=creds, project=os.environ["GCP_PROJECT"])

def dry_run_bytes(bq: bigquery.Client, sql: str) -> int:
    job = bq.query(sql, job_config=bigquery.QueryJobConfig(dry_run=True, use_query_cache=False))
    return job.total_bytes_processed

def run(bq: bigquery.Client, sql: str):
    est = dry_run_bytes(bq, sql)
    if est > MAX_BYTES:
        raise RuntimeError(f"query would scan {est/1e9:.1f} GB, cap is {MAX_BYTES/1e9:.1f} GB")
    cfg = bigquery.QueryJobConfig(maximum_bytes_billed=MAX_BYTES)
    return bq.query(sql, job_config=cfg).to_dataframe(), est