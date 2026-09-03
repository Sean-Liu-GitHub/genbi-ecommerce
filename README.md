# genbi-ecommerce

Evaluation harness for AI-generated SQL, testing how business
definitions, curated schemas, and semantic layers affect accuracy
on ambiguous questions.

**Status: in progress.** The dbt project and definitions are complete.
The eval harness, question set, and comparative results are coming.

## What's here now
- dbt project: staging, intermediate, marts over BigQuery's thelook_ecommerce
- Business definitions: docs/DEFINITIONS.md (ten decisions, each traceable to profiling)
- Schema profiling: docs/SCHEMA_NOTES.md, scripts/profile.sql

## What's coming
- 120-question eval set with ground-truth SQL
- Comparative testing across Gemini in BigQuery, dbt MCP, and Datus
- Ablation: raw schema → descriptions → curated marts → semantic layer
- Monitoring: regression CI, cost per question, drift detection

## Related posts
- [Post #1 title](link)
- [Post #4 title](link)
