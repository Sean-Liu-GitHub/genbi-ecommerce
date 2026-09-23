"""
Eval runner — Stage 4.4

Usage:
    python -m eval.harness.run --arm stub --repeats 1
    python -m eval.harness.run --arm stub --repeats 1 --tier simple_lookup
"""

import argparse
import json
import sys
import time
from datetime import datetime, timezone
from pathlib import Path

import pandas as pd

from agent.config import GCP_PROJECT
from agent.bq import client, run as bq_run
from eval.harness import questions as Q
from eval.harness.grade import grade, classify_failure


RESULTS_DIR = Path(__file__).resolve().parents[2] / "eval" / "results"
AGENTS = {}


def register_agent(name):
    def decorator(fn):
        AGENTS[name] = fn
        return fn
    return decorator


@register_agent("stub")
def stub_agent(question: str, arm: str) -> dict:
    from agent.stub import answer
    return answer(question, arm)


def execute_gt(bq, question: dict) -> pd.DataFrame | None:
    sql = Q.load_gt_sql(question)
    if sql is None:
        return None
    df, _ = bq_run(bq, sql)
    return df


def execute_candidate(bq, response: dict) -> pd.DataFrame | None:
    sql = response.get("sql")
    if not sql:
        return None
    try:
        df, _ = bq_run(bq, sql)
        return df
    except Exception as e:
        return None


def run_question(bq, question: dict, agent_fn, arm: str) -> dict:
    qid = question["id"]
    tier = question["tier"]
    start = time.time()

    response = agent_fn(question["question"], arm)
    latency_ms = int((time.time() - start) * 1000)

    result = {
        "id": qid,
        "tier": tier,
        "question": question["question"],
        "arm": arm,
        "route": response.get("route", "unknown"),
        "generated_sql": response.get("sql"),
        "latency_ms": latency_ms,
        "ts": datetime.now(timezone.utc).isoformat(),
    }

    if tier in ("ambiguous", "unanswerable"):
        result["verdict"] = "needs_judge"
        result["score"] = None
        result["grading"] = "llm_judge"
        return result

    gt_df = execute_gt(bq, question)
    cand_df = execute_candidate(bq, response)

    if gt_df is None:
        result["verdict"] = "no_ground_truth"
        result["score"] = None
        return result

    if cand_df is None:
        result["verdict"] = "execution_error"
        result["score"] = 0.0
        return result

    tol = question.get("tolerance", 0)
    grade_result = grade(cand_df, gt_df, tol)
    result.update(grade_result)
    result["failure_class"] = classify_failure(question, grade_result)
    return result


def run_eval(arm: str, repeats: int, tier: str | None = None):
    if arm not in AGENTS:
        print(f"Unknown arm: {arm}. Available: {list(AGENTS.keys())}")
        sys.exit(1)

    agent_fn = AGENTS[arm]
    all_questions = Q.load_tier(tier) if tier else Q.load_all()
    bq = client()

    all_results = []
    for rep in range(repeats):
        print(f"\n--- Repeat {rep + 1}/{repeats} ---")
        for q in all_questions:
            result = run_question(bq, q, agent_fn, arm)
            result["repeat"] = rep + 1
            all_results.append(result)
            verdict = result.get("verdict", "?")
            print(f"  {result['id']}: {verdict}")

    RESULTS_DIR.mkdir(parents=True, exist_ok=True)
    timestamp = datetime.now().strftime("%Y%m%d_%H%M%S")
    out_path = RESULTS_DIR / f"{arm}_{timestamp}.json"
    out_path.write_text(json.dumps(all_results, indent=2, default=str))
    print(f"\nResults written to {out_path}")

    summary = pd.DataFrame(all_results)
    print("\n=== Summary ===")
    print(f"Total questions: {len(all_questions)}")
    print(f"Repeats: {repeats}")
    print(f"Total runs: {len(all_results)}")
    if "verdict" in summary.columns:
        print("\nVerdict distribution:")
        print(summary["verdict"].value_counts().to_string())
        print("\nBy tier:")
        print(summary.groupby("tier")["verdict"].value_counts().to_string())

    return all_results


def main():
    parser = argparse.ArgumentParser(description="Eval harness runner")
    parser.add_argument("--arm", required=True, help="Agent arm to run")
    parser.add_argument("--repeats", type=int, default=1, help="Number of repeats")
    parser.add_argument("--tier", default=None, help="Run only this tier")
    args = parser.parse_args()
    run_eval(args.arm, args.repeats, args.tier)


if __name__ == "__main__":
    main()
