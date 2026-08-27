# Data provenance

Source: `bigquery-public-data.thelook_ecommerce`
Snapshotted: 2026-08-27
Destination: `genbi-ecommerce.raw_thelook` (US)
Snapshot script: `scripts/snapshot.sql`

The public dataset is synthetic and regenerated periodically.
All ground-truth SQL results and accuracy numbers in this repo
refer to the snapshot above, not to the live public dataset.

## Row counts at snapshot

| Table | Rows |
|---|---|
| orders | 124,858 |
| order_items | 181,162 |
| products | 29,120 |
| users | 100,000 |
| inventory_items | 489,087 |
| distribution_centers | 10 |
| events | 2,425,178 |

## Date range (created_at)

| Table | Min | Max |
|---|---|---|
| events | 2019-01-02 | 2026-08-30 |
| inventory_items | 2018-11-21 | 2026-08-29 |
| order_items | 2019-01-07 | 2026-08-30 |
| orders | 2019-01-07 | 2026-08-26 |
| users | 2019-01-02 | 2026-08-25 |