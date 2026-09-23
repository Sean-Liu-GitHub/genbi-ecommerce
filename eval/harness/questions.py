import yaml
from pathlib import Path

QUESTIONS_DIR = Path(__file__).resolve().parents[1] / "domains" / "ecommerce" / "questions"
ECOMMERCE_DIR = Path(__file__).resolve().parents[1] / "domains" / "ecommerce"


def load_all() -> list[dict]:
    questions = []
    for f in sorted(QUESTIONS_DIR.glob("*.yaml")):
        with open(f) as fh:
            questions.extend(yaml.safe_load(fh))
    return questions


def load_tier(tier: str) -> list[dict]:
    path = QUESTIONS_DIR / f"{tier}.yaml"
    if not path.exists():
        raise FileNotFoundError(f"No question file for tier: {tier}")
    with open(path) as fh:
        return yaml.safe_load(fh)


def load_gt_sql(question: dict) -> str | None:
    sql_path = question.get("ground_truth_sql")
    if not sql_path:
        return None
    full_path = ECOMMERCE_DIR / sql_path
    if not full_path.exists():
        raise FileNotFoundError(f"GT SQL not found: {full_path}")
    return full_path.read_text()


def load_distractor_sql(question: dict) -> str | None:
    sql_path = question.get("distractor_sql")
    if not sql_path:
        return None
    full_path = ECOMMERCE_DIR / sql_path
    if not full_path.exists():
        return None
    return full_path.read_text()
