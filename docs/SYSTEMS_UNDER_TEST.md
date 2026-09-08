# Systems under test — Stage 3.5 findings

Verified 2026-09-08. Each system is a candidate arm in the Stage 4/5 ablation
(`docs/WRITEUP.md` Appendix A in the build guide). Record findings here as
each is checked — do not rely on memory three weeks from now.

## Arm D — dbt MCP server

**Status: blocked on the free tier. Falling back to the `mf` CLI.**

Existing dbt Cloud account (`pj339.us1.dbt.com`, account id `70403103937262`,
originally set up for an unrelated `taxi_rides_ny` project) is on the
`developer_2022` plan. Checked via the Admin API
(`GET /api/v2/accounts/{id}/`):

- `semantic_layer_graphql_api_url`, `semantic_layer_jdbc_url`,
  `semantic_layer_url` are all `null` — no Semantic Layer entitlement.
- A Starter-tier trial exists on the account but expired 2024-07-26.
- `explorer_seats` and `analyst_seats` are both `0` — the seat types that
  gate Semantic Layer / Discovery access on paid plans.

Confirmed against dbt Labs' current docs (fetched live, not from training
data — pricing pages change):

| API | Free Developer | Starter+ |
|---|---|---|
| Administrative API | No | Yes |
| Discovery API | No | Yes |
| Semantic Layer API | No | Yes |

This rules out the build guide's suggested fallback of "use MCP only for
discovery" (Stage 3.5a) — the Discovery API is *also* gated behind Starter
($100/user/month), not just the Semantic Layer API. On this account, dbt
MCP's Semantic Layer tools (`list_metrics`, `get_dimensions`,
`query_metrics`, `get_metrics_compiled_sql`) and Discovery tools are
unavailable.

**Decision:** per the guide's Stage 5.3 contingency, Arm D will be
implemented as a small router built directly on the `mf` CLI (already
verified working locally against BigQuery in Stage 3.3 — 14 metrics, correct
SQL on `--explain`) rather than the hosted dbt MCP server. This is
functionally similar to what the real MCP server's Semantic Layer tools
would do (route to MetricFlow, validate metric/dimension names against the
manifest, execute) — just self-hosted instead of dbt-managed. Not revisited
unless a Starter trial becomes worth the cost later.

## Arm E — Datus agent

**Status: working. Installed via WSL2 Ubuntu (Windows requires WSL per the
build guide), `datus-agent` 0.4.0 from PyPI, plus the `datus-bigquery` 0.1.0
adapter (separate PyPI package, not bundled by default — install with
`datus-pip install datus-bigquery` or `pip install datus-bigquery` into
`~/.datus/venv`).**

Config lives at `~/.datus/conf/agent.yml` (LLM provider + datasource) and
`{project}/.datus/config.yml` (active model target, gitignored — local tool
state, not project source). Datasource `genbi_marts` points at
`dbt_marts` using the `genbi-agent` service account (Stage 0.2's governed
surface — Datus never sees `raw_thelook`), confirmed by `list_tables`
returning only the 13 marts/staging views/tables, never the 7 raw tables.

LLM: OpenAI. `gpt-5.5` and `gpt-5.4-mini` access was granted on the
project's dashboard but propagated inconsistently across API backend nodes
for several minutes (worked on some calls, `model_not_found` on others,
non-deterministically) — settled to consistently available after ~10
minutes. `gpt-4o`/`gpt-4o-mini`/`gpt-3.5-turbo` were reliable immediately.
Note for Stage 5: don't assume a freshly-granted model is usable right away;
verify with a direct `curl` call, not just `/v1/models` (which lists
org-wide visibility, not per-project call access).

**Bug found and patched:** `datus_bigquery`'s `list_tables` returns
qualified names in shorthand — e.g. `genbi-ecommerce.dim_products` — omitting
the dataset when the caller already specified one. When the agent's LLM
naturally echoes that same string back into `describe_table`, Datus's
identifier parser (`parse_bigquery_identifier`, counts dots) reads a 2-part
name as `dataset.table`, so `genbi-ecommerce` gets sent to BigQuery as a
*dataset* ID and is rejected (hyphens are valid in project IDs, not dataset
IDs). The agent self-recovers within 2-3 retries by guessing other
qualifier shapes, but burns tokens doing it — this alone was enough to hit
the OpenAI project's 30k TPM rate limit on `gpt-4o` after just two test
questions.

Patched locally (`~/.datus/venv/lib/python3.12/site-packages/datus_bigquery/connector.py`,
`_qualify_listed_name`) to always return the fully-qualified
`project.dataset.table` (3-part) name instead of the context-dependent
shorthand. A 3-part name parses deterministically — no guessing branch in
`_resolve_table` is needed. Verified via direct connector call: `list_tables`
now returns e.g. `genbi-ecommerce.dbt_marts.dim_products`, and resolving that
string back recovers the correct `(project, dataset, table)` triple.
This is a venv-local patch (gets wiped on `datus-bigquery` reinstall/upgrade)
— not filed upstream yet. Re-apply if the venv is rebuilt for Stage 5.

**Test questions (per Stage 3.5b):**

| # | Question | Result |
|---|---|---|
| 1 | "How many total orders are there?" | Correct: 124,645 (matches `fct_orders`/`fct_order_items` distinct count exactly, Stage 3). Took 4 tool calls: `list_tables` → `describe_table` (failed on the naming bug above, pre-patch) → fell back to direct `execute_sql` with `COUNT(DISTINCT order_id)` on `fct_order_items` — correctly avoided the order-grain fan-out trap without being told to. |
| 2 | "Which product categories had no sales in December 2023?" (anti-join, q306-style) | SQL and execution were correct (`category NOT IN (categories with Dec 2023 sales)`, verified zero NULL categories in that window, all 26 categories present — confirmed independently via `agent/bq.py`). Result set was correctly empty. But the agent's natural-language answer, *"No product categories had sales in December 2023,"* inverts the meaning of that empty result — it reads as zero sales occurred, when the correct reading is "no category was excluded, i.e. every category had sales." **SQL-correct, execution-correct, stated-answer misleading** — a distinct failure mode from both `structural` and `semantic` in the Stage 4.3 taxonomy: the query is airtight and the failure is purely in how the empty result gets glossed into English. Worth a taxonomy label of its own (`presentation`?) when building the grader. |
| 3 | "What's our revenue?" (ambiguous: gross vs net, what period) | See below — required bootstrapping the metadata KB first (a real Stage 3.5b step, not deferred work — see note). |

**Bootstrapping the knowledge base.** The guide's 3.5b lists
`datus-agent bootstrap-kb --datasource thelook --components metadata` as a
step before the three test questions, not optional deferred work — questions
1 and 2 above were run before this was done, which was a mistake in how this
stage was first worked through. Running it exposed a **third bug**, separate
from the `list_tables` naming issue:

`datus-agent bootstrap-kb --datasource genbi_marts --components metadata`
reported `schema_size=0, value_size=0` and logged *"No databases resolved
for datasource genbi_marts (bigquery); skipping schema init"* even with
`dataset: dbt_marts` correctly set in `agent.yml`. Root cause: this
bootstrap code path (`datus/storage/schema_metadata/local_init.py`) reads
the default database from a **different, generic config object**
(`datus.configuration.agent_config.DbConfig`) than the one the SQL-execution
tools use (`datus_bigquery.config.BigQueryConfig`) — and that generic
wrapper only reads a literal `database:` key from the YAML, never `dataset:`.
BigQuery's own connector config calls the same concept `dataset` (matching
BigQuery's own terminology), so a config written correctly for the connector
silently produces an empty value for this unrelated bootstrap path. No code
patch needed — fixed by adding `database: dbt_marts` as an explicit
additional key in `agent.yml` alongside `dataset: dbt_marts`; `BigQueryConfig`
tolerates the extra alias key (its `catalog`/`database` → `project`/`dataset`
normalizer consumes it before pydantic's `extra="forbid"` check runs). After
the fix: `schema_size=13, value_size=13` — all 6 tables and 7 views indexed
with vector embeddings (`qdrant/all-MiniLM-L6-v2-onnx`, downloaded
automatically on first bootstrap).

**With the KB bootstrapped, re-running question 3 showed a real behavioral
change:** the agent used `search_table` (semantic/vector search over the
newly-indexed metadata, including sample rows) instead of blind
`list_tables`, found `fct_orders`, inspected its columns, and correctly
chose `net_revenue` over `gross_revenue` — matching our own D7 definition
without being told it. Computed SQL:
`SELECT SUM(net_revenue) FROM fct_orders WHERE order_status != 'Cancelled'`
(the extra `order_status` filter is redundant but harmless here — header and
line status agree 100% in this snapshot, Q4.3). Result: **$8,022,201.68**,
matching the Stage 3 verified `net_revenue` total exactly. Hit the 30k TPM
rate limit before producing the final natural-language response, but the
tool trace already answers the actual test: **the agent never asked a
clarifying question.** It silently picked net revenue and a lifetime
(no time period) window on a question that's ambiguous on both axes,
matching the correct dbt-team definition by luck/reasonable-default rather
than by asking. This is the real Stage 3.5b finding: default Datus, even
with schema metadata bootstrapped, disambiguates silently rather than
asking — genuine ambiguity-*detection* behavior (if any exists) likely needs
the fuller `semantic_modeling`/`metrics`/`reference_sql` KB components from
Stage 5.4's E2 configuration, not just `metadata`.

## Arm G — Gemini in BigQuery

Status: done in Stage 1.4. See `docs/GEMINI_EXPERIMENT.md`.

## Stage 3.5 checkpoint

All three systems checked, with at least one query run through each and
clarification behavior on the ambiguous question specifically observed
(not just deferred). Three real bugs found in third-party packages along
the way (two in `datus-bigquery`, one venv-patched and kept, one config-only
fix; one dbt-MCP access gap that's a plan limitation, not a bug) —
documented above so they don't need rediscovering in Stage 5.

Proceeding to Stage 4 with:
- **Arm D** = `mf` CLI router (not the hosted dbt MCP server — paywalled on
  the free tier)
- **Arm E** = Datus, metadata KB bootstrapped (schema_size=13). Silently
  disambiguates ambiguous questions rather than asking — Stage 5's E1/E2
  split (metadata-only vs. + semantic models/metrics/reference SQL) should
  test whether the fuller KB changes that, not just accuracy
- **Arm G** = Gemini in BigQuery (done, Stage 1.4)
