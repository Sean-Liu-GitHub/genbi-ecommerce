# scripts/check_guard.py
from agent.bq import client, run, dry_run_bytes

BIG = "SELECT * FROM `bigquery-public-data.github_repos.commits`"

def main():
    c = client()
    est = dry_run_bytes(c, BIG)
    print(f"dry run estimate: {est/1e9:.1f} GB")

    try:
        run(c, BIG)
    except RuntimeError as e:
        print(f"PASS — guard blocked it: {e}")
        return
    print("FAIL — query executed despite the cap")

if __name__ == "__main__":
    main()