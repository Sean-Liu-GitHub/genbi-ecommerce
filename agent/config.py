import os
from pathlib import Path
from dotenv import load_dotenv

load_dotenv(Path(__file__).resolve().parents[1] / ".env")

def require(name: str) -> str:
    v = os.environ.get(name)
    if not v:
        raise RuntimeError(f"{name} missing — check .env at repo root")
    return v

GCP_PROJECT = require("GCP_PROJECT")
MAX_BYTES = int(os.environ.get("MAX_QUERY_BYTES", 10_000_000_000))
DBT_CREDENTIALS = require("GOOGLE_APPLICATION_CREDENTIALS")
AGENT_CREDENTIALS = os.environ.get("AGENT_CREDENTIALS", DBT_CREDENTIALS)
