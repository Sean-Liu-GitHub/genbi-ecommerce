# Gemini in BigQuery — description quality experiment (Stage 1.4)

Test question: "How many items did we sell in 2023?"

## Configurations tested

1. **Raw schema, no column descriptions** — Gemini sees `order_items.status`
   with no guidance on which values to filter.
2. **Vague description** on `order_items.status`: "Sales metrics only include
   complete items by default."
3. **Precise description**: "Line-item fulfilment status. Values: Complete,
   Shipped, Processing, Cancelled, Returned. Sales and revenue metrics count
   only lines with status = 'Complete'; exclude Cancelled and Returned."

## Findings

- Without descriptions, Gemini generated structurally correct SQL but omitted
  the status filter entirely — counting all lines regardless of status.
- With vague descriptions, results were inconsistent across runs — sometimes
  a filter appeared, sometimes not. The vague description was not reliably
  picked up.
- With precise descriptions, Gemini applied the status filter more
  consistently, but still not 100% of the time.

**Key insight:** curation (which tables/columns are visible) fixes structural
failures (wrong join path, wrong grain). Descriptions fix semantic failures
(wrong filter, wrong definition). Neither fixes both. This is the
curation/description orthogonality finding.

## Published writeup

[Better column descriptions made the AI right more often. Not reliably.](https://zhaidata.com/better-column-descriptions-made-the-ai-right-more-often-not-reliably)

## Arm G status

Gemini in BigQuery is Arm G in the Stage 4/5 ablation. It serves as the
baseline native BI feature — no external tooling, no semantic layer.
