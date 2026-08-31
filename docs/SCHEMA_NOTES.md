# Schema notes — `raw_thelook` profiling

Snapshot date: `2026-08-27`
Profiled on: `2026-08-27`
Source script: `scripts/profile.sql`

Fill in every `____` as you work through the blocks. Each finding notes what it
feeds downstream, so you can see which decisions are still blocking later stages.

---

## Block 1 — Size and shape

| Table | Rows | Size (MB) |
|---|---|---|
| orders | 124,858 | 6.7 |
| order_items | 181,162 | 13.6 |
| products | 29,120 | 4.3 |
| users | 100,000 | 19.8 |
| inventory_items | 489,087 | 81.1 |
| distribution_centers | 10 | 0.0 |
| events | 2,425,178 | 385.2 |

**Q1.1** Which table is largest, and will any single-table scan approach the byte cap?
→ `events` is largest at 385.2 MB. No single-table scan comes close to the 10 GB byte cap (total dataset is ~510 MB).

*Feeds:* `docs/DATA.md` row counts, and whether `MAX_QUERY_BYTES` needs raising.

---

## Block 2 — Primary key uniqueness

| Table | Key column | Rows | Distinct keys | Unique? |
|---|---|---|---|---|
| orders | order_id | 124,858 | 124,858 | Yes |
| order_items | id | 181,162 | 181,162 | Yes |
| products | id | 29,120 | 29,120 | Yes |
| users | id | 100,000 | 100,000 | Yes |
| inventory_items | id | 489,087 | 489,087 | Yes |

**Q2.1** Any table where rows ≠ distinct keys?
→ No. All primary keys are unique.

*Feeds:* `unique` + `not_null` tests in Stage 2.6. A failure here means an unexpected
grain and must be understood before writing any ground truth.

---

## Block 3 — Fan-out

**Q3.1** Lines per order: min `1`, median `1`, p95 `4`, max `4`, mean `1.451`

**Q3.2** Measured fan-out error for q301:
- truth (`COUNT(*)` on order_items) = `181,162`
- distractor (`SUM(num_of_item)` after join) = `344,142`
- **error_ratio = `1.900`**

**Q3.3** Does `orders.num_of_item` equal the real line count?
- agrees: `124,858`  disagrees: `0`
- If it disagrees, by how much and in which direction? `N/A — perfect agreement`

*Feeds:* `expected_error_ratio` in q301, the `fanout_double_count` classifier in
Stage 4.3, the fan-out canary test in Stage 2.6, and LinkedIn post #2.

---

## Block 4 — Status conflict

**Q4.1** Distinct values of `orders.status`: `Shipped, Complete, Processing, Cancelled, Returned`

**Q4.2** Distinct values of `order_items.status`: `Shipped, Complete, Processing, Cancelled, Returned`

**Q4.3** Line-level disagreement rate between header and line status: `0%`

**Q4.4** How many orders have *mixed* line statuses (no single correct header value)?
→ `0`

**Q4.5** Decision: which status is canonical? → `order_items.status`
Reasoning: `Q4.4 shows zero mixed-status orders, so header and
line agree in this snapshot. Line-level is still canonical
because status is observed per item (each item ships and
returns independently), and future data may introduce mixed
states. Choosing line-level now avoids a silent regression.`

*Feeds:* `accepted_values` tests, `DEFINITIONS.md`, q304, and the `order_status`
dimension in the semantic model.

---

## Block 5 — Cost source

**Q5.1** `products.cost` vs `inventory_items.cost`:
- same: `489,087`  different: `0`  (`0%`)
- mean absolute difference: `0.0`

**Q5.2** Denormalised copies in `inventory_items` vs `products`:
- category mismatches: `0`
- brand mismatches: `0`
- retail_price mismatches: `0`

**Q5.3** Lines sold below cost: `0` (`0%`) — plausible or a data artifact? `Data artifact. Real ecommerce has clearance, loss leaders, and
pricing errors. Zero below-cost lines means the generator constrained
sale_price ≥ cost. Margin analysis on this dataset won't surface
negative-margin edge cases. Note in DEFINITIONS.md and don't write
eval questions that depend on below-cost lines existing.`

**Q5.4** Decision: which cost column is canonical? → `inventory_items.cost`
Reasoning: `Q5.1 shows 0% divergence — products.cost and
inventory_items.cost are identical in this snapshot. Choosing
inventory_items.cost anyway because it's the physically correct
grain: cost attaches to the unit sold, not to the catalog entry.
A real warehouse would have cost changes over time (supplier
renegotiations, currency shifts, bulk discounts), and
inventory_items.cost would diverge from products.cost for older
stock. Building on the right grain now avoids a silent regression
when porting to real data.`

*Feeds:* `DEFINITIONS.md`, `int_order_items_enriched`, q303, the `gross_margin` metric.

---

## Block 6 — Timestamps

**Q6.1** `order_items` date ranges:

| Column | Min | Max |
|---|---|---|
| created_at | 2019-01-07 | 2026-08-30 |
| shipped_at | 2019-01-11 | 2026-08-29 |
| delivered_at | 2019-01-29 | 2026-09-02 |
| returned_at | 2019-02-05 | 2026-09-04 |

**Q6.2** Future-dated rows: `1,065` rows (`0.59%`), furthest future date `2026-08-30`

**Q6.3** Rows and revenue per year — note the partial years at both ends:

| Year | Rows | Revenue |
|---|---|---|
| 2019 | 1,570 | $97,913 |
| 2020 | 4,886 | $301,597 |
| 2021 | 9,272 | $556,367 |
| 2022 | 14,054 | $829,622 |
| 2023 | 20,448 | $1,222,346 |
| 2024 | 29,397 | $1,741,585 |
| 2025 | 44,789 | $2,657,507 |
| 2026 | 56,746 | $3,404,697 |

**Q6.4** Timestamp ordering violations:
- shipped before created: `35,497`
- delivered before shipped: `0`
- returned before delivered: `0`

**Q6.5** Decision: `as_of_date` = `2026-08-27`
Decision: which timestamp anchors revenue (order / ship / deliver / sold_at)? → `order_items.created_at`
Reasoning: `Three real candidates, not four. sold_at is entirely null
and discarded. shipped_at and delivered_at are null for unfulfilled
orders, so either one silently excludes in-progress orders from
revenue. created_at is never null, lives on the same table as
sale_price, and represents the demand-side event.`

*Feeds:* the `as_of_date` var in `dbt_project.yml`, the staging filter, the
`expression_is_true` test, `agg_time_dimension` in the semantic model, and at least
one `ambiguous`-tier question about which date "sales in March" means.

---

## Block 7 — Nulls and orphans

**Q7.1** Null rates in `order_items`:
- inventory_item_id: `0%`
- product_id: `0%`
- user_id: `0%`
- sale_price: `0%`

**Q7.2** Orphaned foreign keys:
- order_items → inventory_items: `0`
- inventory_items → products: `0`
- order_items → users: `0`

**Q7.3** Products never sold: `59`

*Feeds:* whether staging joins must be `LEFT` or can be `INNER`, `relationships`
tests, and q306 (the anti-join question needs a non-zero answer here).

---

## Block 8 — Categorical cardinality

| Dimension | Distinct values |
|---|---|
| product category | 26 |
| product brand | 2,756 |
| product department | 2 |
| user state | 229 |
| user country | 15 |
| traffic source | 5 |

**Q8.1** Any near-duplicate categorical values (whitespace, casing)? → No near-duplicates found.

*Feeds:* which dimensions go in the semantic model, and whether staging needs
`TRIM`/`INITCAP` cleaning. High-cardinality dimensions like brand are good
group-by targets for testing result-set size handling.

---

## Block 9 — Returns

**Q9.1** Returned lines: `18,273` of `181,162` (`10.09%`)

**Q9.2** Gross revenue: `$10,811,633`  Revenue excluding returns: `$9,707,838`
Difference: `$1,103,795` (`10.21%`)

**Q9.3** Does `status = 'Returned'` always coincide with `returned_at IS NOT NULL`?
- status but no timestamp: `0`
- timestamp but no status: `0`

**Q9.4** Orders with partial returns (some lines returned, some not): `0`

*Feeds:* the `net_revenue` definition, q304, and whether `fct_orders.is_returned`
can be a boolean or needs to be a proportion.

---

## Block 10 — Category spanning

**Q10.1** Orders spanning more than one product category: `35,739` (`28.62%`)

*Feeds:* q310 — this percentage is what makes "AOV by category" genuinely
ambiguous rather than merely fiddly. If it is near zero, q310 needs rewriting.

---

## Block 11 — Redundancy traps

**Q11.1** Do the two paths from `order_items` to `products` agree?
(`oi.product_id` vs `oi.inventory_item_id → ii.product_id`)
- disagreements: `0` (`0%`)

**Q11.2** Denormalised `inventory_items` fields vs `products` — see Q5.2.

**Q11.3** `inventory_items.sold_at` vs `order_items.created_at`:
- sold_at null: `181,162` (all sold items — column is never populated)
- timestamps differ: `0`
- mean absolute difference: `N/A` seconds

**Q11.4** `orders.gender` vs `users.gender` disagreements: `0`

**Q11.5** `orders.returned_at` vs `order_items.returned_at`:
- header only: `0`
- line only: `0`

**Q11.6** `order_items.user_id` vs `orders.user_id` disagreements: `0`

**Q11.7** Discounted lines (`sale_price` ≠ `products.retail_price`): `0` (`0%`)

**Q11.8** Decision: which join path does `int_order_items_enriched` use? → `order_items.inventory_item_id → inventory_items.id → inventory_items.product_id → products.id`

Reasoning: 
1. Consistency with D2. We already chose inventory_items.cost as the
   canonical cost column. Going through inventory_items picks up cost
   in the same join rather than requiring a second join to a different
   table for one column.

2. Physical grain. inventory_items represents the specific unit sold.
   order_items.product_id is a denormalised shortcut that happens to
   agree in this dataset but could diverge in a real warehouse
   (product substitutions, inventory reassignments, catalog merges).

3. One join chain, one grain. The intermediate model joins
   oi → ii → p → dc in a single chain at line grain. Path 1 would
   fork: oi → p for product attributes, oi → ii for cost. Two paths
   to the same entity in one model is exactly the ambiguity we're
   trying to eliminate.


*Feeds:* the intermediate model design, q303 and q305, and — if Q11.1 is non-zero —
a new trap category worth its own eval questions and its own post.

---

## Decisions summary

Carry these into `docs/DEFINITIONS.md`. Every one must be resolved before writing
ground-truth SQL.

| # | Decision | Value | Source |
|---|---|---|---|
| D1 | Canonical status (header or line) | `order_items.status` (line-level) | Q4.5 |
| D2 | Canonical cost column | `inventory_items.cost` | Q5.4 |
| D3 | Revenue anchor timestamp | `order_items.created_at` (order date) | Q6.5 |
| D4 | `as_of_date` | `2026-08-27` | Q6.5 |
| D5 | Join path to products | `oi → ii → p` (via `inventory_item_id`) | Q11.8 |
| D6 | `gross_revenue` definition | `SUM(sale_price)`, all statuses | Q9.2 |
| D7 | `net_revenue` definition | `SUM(sale_price)` where `status NOT IN ('Returned','Cancelled')` | Q9.2 |
| D8 | `active_user` window | ordered in trailing 90 days | — |
| D9 | Category attribution for multi-category orders | line-level (each line carries its own category, no order-level attribution) | Q10.1 |
| D10 | Discount handling (retail vs sale price) | `sale_price` is actual revenue; `retail_price` is list price. No discounting exists in this dataset (Q11.7: 0%). `sale_price` is the only revenue column. | Q11.7 |

---

## Surprises log

Anything that did not match expectations. These are the best source of eval
questions and writeup material — record them even if you are not sure they matter yet.

| Finding | Where noticed | Turned into question? |
|---|---|---|
| `shipped_at < created_at` for 35,497 rows (19.6%) — shipping timestamp precedes order creation | B6 Q6.4 | Yes — ambiguous tier: "When did order X ship?" tests whether the system notices the impossible timestamp and flags it rather than answering confidently |
| `inventory_items.sold_at` is NULL for all 181,162 sold items — column exists but is never populated | B11 Q11.3 | Yes — unanswerable tier: "When was inventory item 5023 sold?" The model will write `SELECT sold_at` and return NULL, which looks like "not sold" when the item was sold |
| Zero cost/brand/category/retail_price mismatches across all denormalized copies — dataset is perfectly consistent | B5 Q5.2, B11 Q11.2 | No — note as dataset limitation. In a real warehouse these would diverge, and the join-path decision (D5) would have measurable accuracy consequences |
| Zero discount: `sale_price` always equals `products.retail_price` | B11 Q11.7 | No — note as dataset limitation. "What's our average discount rate?" is unanswerable (answer is 0%, but misleadingly so) |
| Zero lines sold below cost | B5 Q5.3 | No — don't write margin questions that depend on negative margins existing |
| 28.62% of orders span multiple product categories — AOV-by-category is genuinely ambiguous | B10 Q10.1 | Yes — ambiguous tier q310: "What was average order value by product category in 2023?" Correct behavior is to ask how to attribute multi-category orders |
| No partial returns — every order is either fully returned or not returned at all | B9 Q9.4 | No — simplifies D7 (boolean is_returned, not a proportion) but note as limitation. Real ecommerce has partial returns and the net_revenue logic is harder |
| Header and line status always agree, no mixed-status orders — status redundancy is benign | B4 Q4.3, Q4.4 | No — D1 chose line-level anyway for structural correctness. Note that this dataset won't surface the failure mode where header and line disagree |
| Fan-out error ratio is 1.9× not equal to mean_lines (1.451) — the error is size-biased (Σn²/Σn), not the simple average | B3 Q3.2 | Yes — q301, and a detail worth explaining in the writeup |
| 59 products never sold | B7 Q7.3 | Yes — anti-join tier q306: "Which product categories had no sales in December 2023?" Needs non-zero never-sold products to be meaningful |
| `sold_at` entirely null while the column name strongly implies it should be populated — an LLM will use it confidently | B11 Q11.3 | Yes — strongest unanswerable-tier question. The failure is invisible: the query runs, returns NULL, and looks like a valid "not yet sold" answer |
