# Business definitions — thelook ecommerce

This document resolves every ambiguous term in the `raw_thelook` schema before
any metric, model, or AI-generated query is built. Each definition is traceable
to a profiling finding in `docs/SCHEMA_NOTES.md`.

In a client engagement, this document is the primary deliverable of a Readiness
Audit. It is agreed with stakeholders before any tooling is configured.

Data snapshot: `2026-08-27`
As-of date: `2026-08-27` (rows after this date are synthetic future data and
excluded at the staging layer)

---

## Revenue

**Gross revenue:** the sum of `order_items.sale_price` across all line statuses,
including returned and cancelled lines. This represents total demand before
any adjustments.

**Net revenue:** the sum of `order_items.sale_price` where
`order_items.status NOT IN ('Returned', 'Cancelled')`. This is the default
revenue metric. When a question says "revenue" or "sales" without
qualification, it means net revenue.

The difference is material: gross revenue is $10,811,633; net revenue is
$9,707,838 — a 10.2% gap. (Source: Q9.2)

**Revenue anchor date:** `order_items.created_at` — the timestamp the order was
placed. All period-based revenue questions ("sales in March", "Q2 revenue")
filter on this column.

Alternatives considered:
- `shipped_at` — null for unshipped orders, would silently exclude in-progress sales
- `delivered_at` — null for undelivered orders, same problem
- `inventory_items.sold_at` — entirely null in this dataset (Source: Q11.3)

A question like "what were sales in March by delivery date" is treated as
ambiguous: the system should ask which date basis to use rather than silently
picking one.

---

## Order status

**Canonical status column:** `order_items.status` (line-level), not
`orders.status` (header-level).

**Values:** Complete, Shipped, Processing, Cancelled, Returned.

In this dataset, header and line status always agree (0% conflict rate, 0
mixed-status orders). Line-level is still canonical because status is observed
per item — each item ships and returns independently — and a real warehouse
will produce mixed-status orders. (Source: Q4.3, Q4.4)

**"Sold" means:** `status NOT IN ('Returned', 'Cancelled')`. This includes
Complete, Shipped, and Processing. A line in Processing status is counted as
a sale because the customer committed to buy; it has not been cancelled.

`status = 'Returned'` and `returned_at IS NOT NULL` are perfectly aligned in
this dataset (Source: Q9.3). The status column is preferred for filtering
because it also captures Cancelled, which `returned_at` does not cover.

---

## Cost and margin

**Unit cost:** `inventory_items.cost` — the cost of the specific physical item
sold, not `products.cost` (the current catalog cost). In this dataset they are
identical (0% divergence, Source: Q5.1), but a real warehouse would have cost
changes over time from supplier renegotiations, currency shifts, and bulk
discounts.

**Line margin:** `order_items.sale_price - inventory_items.cost`

**Gross margin (metric):** `SUM(line_margin)` across qualifying lines.

**Margin percent:** `gross_margin / NULLIF(net_revenue, 0)`

**Dataset limitation:** zero lines are sold below cost (Source: Q5.3). This is
a generator artifact. Do not write eval questions that depend on negative
margins existing.

---

## Pricing

**`sale_price`** (on `order_items`): the actual amount the customer paid for
this line. This is the revenue figure.

**`retail_price`** (on `products`): the list price in the catalog.

**`cost`** (on `inventory_items`): the acquisition cost of this unit.

In this dataset, `sale_price` always equals `retail_price` — there is no
discounting (0% discounted lines, Source: Q11.7). This is a generator artifact.
In a real warehouse, the gap between the two is the discount, and discount
analysis would be a common metric.

---

## Join path to products

**Canonical path:** `order_items.inventory_item_id → inventory_items.id →
inventory_items.product_id → products.id`

Not the shorter `order_items.product_id → products.id`.

In this dataset the two paths agree (0% divergence, Source: Q11.1). The longer
path is chosen because:

1. It is consistent with D2 — `inventory_items.cost` is picked up in the same
   join chain rather than requiring a fork
2. It reflects the physical unit sold, not the catalog entry at time of order
3. It produces one join chain at one grain, eliminating the ambiguity that
   causes an LLM to pick the wrong path

The intermediate dbt model (`int_order_items_enriched`) makes this join once.
Everything downstream reads the intermediate model and physically cannot take
the wrong path.

---

## Active user

**Definition:** a user who placed at least one order in the trailing 90 days
from the as-of date.

**"Placed an order" means:** at least one row in `order_items` with
`created_at` in the window. Status is not considered — a user who ordered and
then returned everything is still active (they engaged with the business).

The 90-day window is a convention, not a discovery. A real engagement would
test 30, 60, 90, and 180-day windows and choose based on reactivation patterns.

---

## Category attribution

**Category lives on the line, not the order.** Each `order_item` carries its
own category through the join to `products`.

28.62% of orders span more than one product category (Source: Q10.1). This
means "revenue by category" is well-defined at line grain but "AOV by category"
at order grain is genuinely ambiguous — a $100 order with items from two
categories cannot be attributed to one.

Questions that request order-level metrics grouped by category are treated as
ambiguous: the system should ask how to attribute rather than silently picking
a method.

---

## Returns

**Return rate:** 10.09% of lines are returned (Source: Q9.1).

**No partial returns exist** in this dataset — every order is either fully
returned or not returned at all (Source: Q9.4). This means
`fct_orders.is_returned` can be a simple boolean. In a real warehouse, partial
returns are common and this field would need to be a count or proportion.

---

## Timestamps — known data-quality issue

19.6% of lines have `shipped_at < created_at` — the shipping timestamp
precedes the order creation timestamp (Source: Q6.4). This is a generator bug,
not a business scenario.

`delivered_at < shipped_at` and `returned_at < delivered_at` are both zero,
so the post-shipment chain is internally consistent.

This issue does not affect revenue (anchored on `created_at`) but would affect
any shipping-time or fulfillment-speed analysis. Note in the writeup as a
dataset limitation.

---

## Unused columns

**`inventory_items.sold_at`:** entirely null for all 181,162 sold items
(Source: Q11.3). The column exists but is never populated. Excluded from all
models. An LLM seeing this column will confidently use it and return NULL,
which looks like "not yet sold" when the item was in fact sold — this is an
eval question.

**`user_geom`** and **`distribution_center_geom`:** GEOGRAPHY columns. Excluded
from staging to avoid inflated bytes scanned and `to_dataframe()` conversion
failures.

**`orders.gender`:** redundant with `users.gender` (0% disagreement,
Source: Q11.4). Excluded from staging; gender is sourced from `dim_users` only.

---

## Dataset limitations

These are properties of the synthetic data that would not hold in a real
warehouse. Note them so the eval results are interpreted correctly.

| Limitation | Impact |
|---|---|
| Zero cost divergence between `products` and `inventory_items` | D2 and D5 are untested by the data |
| Zero discounting (`sale_price` = `retail_price`) | No discount-related questions |
| Zero below-cost sales | No negative-margin edge cases |
| Zero partial returns | `is_returned` is boolean, not proportional |
| Zero mixed-status orders | D1 is untested by the data |
| Zero join-path divergence | D5 is untested by the data |
| `sold_at` entirely null | Fourth timestamp candidate eliminated |
| `shipped_at < created_at` on 19.6% of rows | Fulfillment-speed analysis unreliable |
| All denormalized copies perfectly consistent | No entity-resolution challenges |