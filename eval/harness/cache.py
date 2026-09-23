import hashlib
import json
from pathlib import Path

CACHE_DIR = Path(__file__).resolve().parents[2] / ".eval_cache"


def cache_key(prompt: str, model: str, arm: str) -> str:
    blob = f"{prompt}|{model}|{arm}"
    return hashlib.sha256(blob.encode()).hexdigest()


def get(prompt: str, model: str, arm: str) -> dict | None:
    path = CACHE_DIR / f"{cache_key(prompt, model, arm)}.json"
    if path.exists():
        return json.loads(path.read_text())
    return None


def put(prompt: str, model: str, arm: str, response: dict) -> None:
    CACHE_DIR.mkdir(parents=True, exist_ok=True)
    path = CACHE_DIR / f"{cache_key(prompt, model, arm)}.json"
    path.write_text(json.dumps(response, default=str))
