"""
LLM judge for ambiguous and unanswerable tiers.

Evaluates whether the agent's response appropriately asked for
clarification (ambiguous) or refused with explanation (unanswerable).
"""

import os
from pathlib import Path
from dotenv import load_dotenv
from openai import OpenAI

load_dotenv(Path(__file__).resolve().parents[2] / ".env")

MODEL = os.environ.get("OPENAI_JUDGE_MODEL", os.environ.get("OPENAI_MODEL", "gpt-5.4"))

JUDGE_PROMPT = """You are an eval judge for a text-to-SQL system. Your job is to evaluate whether the system's response to an ambiguous or unanswerable question was appropriate.

## Question
{question}

## Expected behavior
Tier: {tier}
Criteria: {judge_criteria}

## System's response
Route: {route}
{response_detail}

## Scoring rules

For **ambiguous** questions:
- PASS: The system asked a clarifying question that addresses the ambiguity described in the criteria. It does not need to cover every ambiguity — addressing at least one key ambiguity earns a pass.
- PARTIAL: The system acknowledged some ambiguity but still proceeded to answer without fully clarifying, OR asked about a minor ambiguity while missing the main one.
- FAIL: The system answered directly without acknowledging any ambiguity, or asked an irrelevant clarifying question.

For **unanswerable** questions:
- PASS: The system refused to answer and correctly explained why the data cannot support the question, consistent with the criteria.
- PARTIAL: The system expressed uncertainty or caveats but still attempted an answer.
- FAIL: The system answered confidently with SQL or a result, ignoring that the question cannot be answered from the schema.

## Output format
Respond with exactly three lines:
VERDICT: PASS|PARTIAL|FAIL
SCORE: 1.0|0.5|0.0
REASON: <one sentence explaining your judgment>"""


def _format_response_detail(response: dict) -> str:
    route = response.get("route", "unknown")
    if route == "clarify":
        return f"Clarifying question: {response.get('message', '')}"
    elif route == "refuse":
        return f"Refusal: {response.get('message', '')}"
    elif route == "sql":
        sql = response.get("sql", "")
        return f"Generated SQL: {sql}"
    else:
        raw = response.get("raw_response", "")
        return f"Raw response: {raw[:500]}"


def judge(question: dict, response: dict) -> dict:
    client = OpenAI()

    prompt = JUDGE_PROMPT.format(
        question=question["question"],
        tier=question["tier"],
        judge_criteria=question.get("judge_criteria", ""),
        route=response.get("route", "unknown"),
        response_detail=_format_response_detail(response),
    )

    resp = client.chat.completions.create(
        model=MODEL,
        messages=[{"role": "user", "content": prompt}],
        temperature=0,
        max_completion_tokens=256,
    )

    text = resp.choices[0].message.content.strip()
    result = {"raw_judge_response": text}

    for line in text.split("\n"):
        line = line.strip()
        if line.startswith("VERDICT:"):
            result["verdict"] = line.split(":", 1)[1].strip().lower()
        elif line.startswith("SCORE:"):
            try:
                result["score"] = float(line.split(":", 1)[1].strip())
            except ValueError:
                result["score"] = 0.0
        elif line.startswith("REASON:"):
            result["reason"] = line.split(":", 1)[1].strip()

    if "verdict" not in result:
        result["verdict"] = "judge_error"
        result["score"] = 0.0

    return result
