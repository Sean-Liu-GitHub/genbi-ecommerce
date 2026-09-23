import pandas as pd


def normalize(df: pd.DataFrame, tol: float) -> set:
    d = df.copy()
    d.columns = [c.lower() for c in d.columns]
    d = d.reindex(sorted(d.columns), axis=1)
    for c in d.select_dtypes("number"):
        d[c] = d[c].round(6 if tol == 0 else 2)
    return set(map(tuple, d.astype(str).values.tolist()))


def grade(candidate: pd.DataFrame, truth: pd.DataFrame, tol: float) -> dict:
    c, t = normalize(candidate, tol), normalize(truth, tol)
    if c == t:
        return {"verdict": "correct", "score": 1.0}
    overlap = len(c & t) / max(len(t), 1)
    if candidate.shape != truth.shape:
        return {"verdict": "wrong_shape", "score": 0.0, "overlap": overlap}
    return {"verdict": "wrong_values", "score": 0.0, "overlap": overlap}


def classify_fanout(cand_val, truth_val, ratio: float | None) -> str | None:
    if ratio and truth_val and abs(cand_val / truth_val - ratio) < 0.05:
        return "fanout_double_count"
    return None


def classify_failure(question: dict, result: dict) -> str | None:
    if result["verdict"] == "correct":
        return None
    trap = question.get("trap")
    if trap and trap.startswith("fanout"):
        return "structural"
    if trap and trap in ("wrong_cost_column", "wrong_join_path", "sold_at_null"):
        return "structural"
    if trap and trap in ("wrong_status_filter", "wrong_timestamp"):
        return "semantic"
    return "unknown"
