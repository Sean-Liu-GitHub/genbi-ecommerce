"""
Text-to-SQL agent for Arms A, B, and C.

Sends the question + schema context to OpenAI, extracts SQL,
validates with sqlglot, and returns the result.
"""

import os
import re

import sqlglot
from openai import OpenAI

from agent.config import GCP_PROJECT
from agent.context import build_context

MODEL = os.environ.get("OPENAI_MODEL", "gpt-5.4")

SYSTEM_PROMPT = """You are a SQL analyst. Given a user question and a BigQuery schema, write a single SELECT query that answers the question.

Rules:
- Write BigQuery Standard SQL.
- Use fully qualified table names (project.dataset.table).
- Return ONLY the SQL query, no explanation, no markdown fences.
- If the question is ambiguous or cannot be answered from the schema, respond with exactly: CLARIFY: <your clarifying question>
- If the question cannot be answered at all from the available data, respond with exactly: REFUSE: <reason>

Schema:
{schema}"""


def _build_messages(question: str, schema: str) -> list[dict]:
    return [
        {"role": "system", "content": SYSTEM_PROMPT.format(schema=schema)},
        {"role": "user", "content": question},
    ]


def _extract_sql(response_text: str) -> dict:
    text = response_text.strip()

    if text.upper().startswith("CLARIFY:"):
        return {"route": "clarify", "sql": None, "message": text[8:].strip()}

    if text.upper().startswith("REFUSE:"):
        return {"route": "refuse", "sql": None, "message": text[7:].strip()}

    sql = text
    if sql.startswith("```"):
        match = re.search(r"```(?:sql)?\s*\n?(.*?)```", sql, re.DOTALL)
        if match:
            sql = match.group(1).strip()

    return {"route": "sql", "sql": sql}


def _validate_sql(sql: str) -> str | None:
    try:
        stmts = sqlglot.parse(sql, dialect="bigquery")
    except sqlglot.errors.ParseError as e:
        return f"Parse error: {e}"
    if len(stmts) != 1:
        return f"Expected 1 statement, got {len(stmts)}"
    stmt = stmts[0]
    if stmt.key != "select":
        return f"Expected SELECT, got {stmt.key.upper()}"
    return None


def _call_openai(messages: list[dict], model: str) -> str:
    client = OpenAI()
    resp = client.chat.completions.create(
        model=model,
        messages=messages,
        temperature=0,
        max_completion_tokens=2048,
    )
    return resp.choices[0].message.content


def answer(question: str, arm: str) -> dict:
    schema = build_context(arm)
    messages = _build_messages(question, schema)
    response_text = _call_openai(messages, MODEL)
    result = _extract_sql(response_text)

    if result["route"] != "sql" or result["sql"] is None:
        result["raw_response"] = response_text
        return result

    validation_error = _validate_sql(result["sql"])
    if validation_error:
        messages.append({"role": "assistant", "content": response_text})
        messages.append({"role": "user", "content": (
            f"Your SQL has an error: {validation_error}. "
            "Please fix it and return only the corrected SQL."
        )})
        retry_text = _call_openai(messages, MODEL)
        retry_result = _extract_sql(retry_text)
        if retry_result["route"] == "sql" and retry_result["sql"]:
            retry_error = _validate_sql(retry_result["sql"])
            if retry_error is None:
                retry_result["retried"] = True
                retry_result["raw_response"] = retry_text
                return retry_result
        result["validation_error"] = validation_error
        result["raw_response"] = response_text

    return result
