"""
Schema context builders for Arms A, B, and C.

Arm A: raw INFORMATION_SCHEMA column list, no descriptions
Arm B: raw tables + mart tables with model/column descriptions from manifest.json
Arm C: mart tables only with descriptions (raw tables hidden)
"""

import json
from pathlib import Path

from agent.bq import client as bq_client

MANIFEST_PATH = Path(__file__).resolve().parents[1] / "dbt_project" / "thelook" / "target" / "manifest.json"
RAW_DATASET = "raw_thelook"
MARTS_DATASET = "dbt_marts"
PROJECT = "genbi-ecommerce"

MART_MODELS = [
    "fct_order_items",
    "fct_orders",
    "dim_users",
    "dim_products",
]


def _load_manifest() -> dict:
    with open(MANIFEST_PATH) as f:
        return json.load(f)


def _query_information_schema(dataset: str) -> dict[str, list[dict]]:
    bq = bq_client()
    sql = f"""
    SELECT table_name, column_name, data_type
    FROM `{PROJECT}.{dataset}.INFORMATION_SCHEMA.COLUMNS`
    ORDER BY table_name, ordinal_position
    """
    from google.cloud import bigquery
    df = bq.query(sql, job_config=bigquery.QueryJobConfig(
        maximum_bytes_billed=10_000_000_000)).to_dataframe()
    tables = {}
    for _, row in df.iterrows():
        tables.setdefault(row["table_name"], []).append({
            "column": row["column_name"],
            "type": row["data_type"],
        })
    return tables


def _format_raw_schema(tables: dict[str, list[dict]]) -> str:
    lines = []
    for table, cols in sorted(tables.items()):
        lines.append(f"Table: `{PROJECT}.{RAW_DATASET}.{table}`")
        for c in cols:
            lines.append(f"  {c['column']} {c['type']}")
        lines.append("")
    return "\n".join(lines)


def _format_mart_schema_from_manifest(manifest: dict) -> str:
    lines = []
    for model_name in MART_MODELS:
        key = f"model.thelook.{model_name}"
        node = manifest["nodes"].get(key, {})
        model_desc = node.get("description", "")
        lines.append(f"Table: `{PROJECT}.{MARTS_DATASET}.{model_name}`")
        if model_desc:
            lines.append(f"  Description: {model_desc}")
        columns = node.get("columns", {})
        for col_name, col_info in columns.items():
            col_desc = col_info.get("description", "")
            col_type = col_info.get("data_type", col_info.get("type", ""))
            desc_part = f" — {col_desc}" if col_desc else ""
            type_part = f" {col_type}" if col_type else ""
            lines.append(f"  {col_name}{type_part}{desc_part}")
        lines.append("")
    return "\n".join(lines)


def _format_raw_schema_with_descriptions(
    raw_tables: dict[str, list[dict]], manifest: dict
) -> str:
    source_nodes = {
        k: v for k, v in manifest.get("sources", {}).items()
        if "thelook" in k
    }
    source_descs = {}
    for key, node in source_nodes.items():
        table_name = node.get("name", "")
        source_descs[table_name] = {
            "model_desc": node.get("description", ""),
            "columns": {
                c_name: c_info.get("description", "")
                for c_name, c_info in node.get("columns", {}).items()
            },
        }

    lines = []
    for table, cols in sorted(raw_tables.items()):
        lines.append(f"Table: `{PROJECT}.{RAW_DATASET}.{table}`")
        sd = source_descs.get(table, {})
        if sd.get("model_desc"):
            lines.append(f"  Description: {sd['model_desc']}")
        for c in cols:
            col_desc = sd.get("columns", {}).get(c["column"], "")
            desc_part = f" — {col_desc}" if col_desc else ""
            lines.append(f"  {c['column']} {c['type']}{desc_part}")
        lines.append("")
    return "\n".join(lines)


_raw_schema_cache: dict[str, list[dict]] | None = None


def _get_raw_schema() -> dict[str, list[dict]]:
    global _raw_schema_cache
    if _raw_schema_cache is None:
        _raw_schema_cache = _query_information_schema(RAW_DATASET)
    return _raw_schema_cache


def build_context(arm: str) -> str:
    if arm == "A":
        raw = _get_raw_schema()
        return _format_raw_schema(raw)
    elif arm == "B":
        raw = _get_raw_schema()
        manifest = _load_manifest()
        raw_part = _format_raw_schema_with_descriptions(raw, manifest)
        mart_part = _format_mart_schema_from_manifest(manifest)
        return raw_part + "\n" + mart_part
    elif arm == "C":
        manifest = _load_manifest()
        return _format_mart_schema_from_manifest(manifest)
    else:
        raise ValueError(f"Unknown arm: {arm}. Expected A, B, or C.")
