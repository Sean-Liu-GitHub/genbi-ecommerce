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
| 3 | "What's our revenue?" (ambiguous: gross vs net, what period) | Routed to `task(type=ask_metrics)` → `search_metrics`, correctly recognizing this as metric-shaped rather than attempting freeform SQL. First attempt failed outright: the `dosi` semantic adapter package (`datus-semantic-dosi`, separate from `datus-bigquery`) wasn't installed (`pip install datus-semantic-dosi`, pulls in a ~46MB `dosi-engine` wheel). After installing it, `search_metrics` runs successfully but returns an **empty** result — Datus's own metric catalog is unpopulated by default; nothing has been bootstrapped into it yet (per the guide, that needs `/gen_semantic_model` or feeding it `manifest.json`, deferred to Stage 5). Response: *"there isn't a readily available metric... if you have a specific metric name, I can retrieve it."* |

**Ambiguity/clarification finding:** not yet observed. On this question, Datus
never reached a fork where it had a *candidate* metric to disambiguate — its
catalog was simply empty, so it reported "not found" rather than "which one
did you mean." Genuine clarification behavior (asking gross vs. net,
which period) requires the metric catalog to be populated first — deferred
to Stage 5's Arm E wrapper, where feeding Datus the dbt `manifest.json` (or
wiring its `semantic_layer: metricflow: {}` adapter directly to our
MetricFlow project) is the more informative configuration for the D vs E
comparison than its own from-scratch RAG catalog.

## Stage 3.5 checkpoint

All three systems checked, at least one query run through each, dbt MCP's
paywall and Datus's two missing-adapter gaps found and resolved/documented.
Proceeding to Stage 4 with: Arm D = `mf` CLI router (not hosted dbt MCP),
Arm E = Datus (bootstrap KB before ambiguity testing in Stage 5), Arm G =
Gemini in BigQuery (done, Stage 1.4).

## Arm G — Gemini in BigQuery

Status: done in Stage 1.4. See `docs/GEMINI_EXPERIMENT.md`.
