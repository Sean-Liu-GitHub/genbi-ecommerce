-- scripts/profile.sql
-- Stage 1.2 schema profiling for genbi-ecommerce.raw_thelook
--
-- Run each block separately and record the answer in docs/SCHEMA_NOTES.md.
-- Column names below are my best guess at thelook_ecommerce; run block 0 FIRST
-- and correct anything that does not match before running the rest.

-- ============================================================
-- 0. COLUMN INVENTORY  (run this first, fix names below if needed)
-- ============================================================

SELECT table_name, ordinal_position, column_name, data_type
FROM `genbi-ecommerce.raw_thelook.INFORMATION_SCHEMA.COLUMNS`
ORDER BY table_name, ordinal_position;


-- ============================================================
-- 1. SIZE AND SHAPE  -> fills the row-count table in docs/DATA.md
-- ============================================================

SELECT table_id AS table_name, row_count, ROUND(size_bytes/1e6, 1) AS size_mb
FROM `genbi-ecommerce.raw_thelook.__TABLES__`
ORDER BY row_count DESC;


-- ============================================================
-- 2. PRIMARY KEY UNIQUENESS  -> are the "id" columns actually unique?
-- ============================================================

SELECT 'orders'               AS t, COUNT(*) AS rows, COUNT(DISTINCT order_id) AS distinct_key FROM `genbi-ecommerce.raw_thelook.orders`
UNION ALL SELECT 'order_items',       COUNT(*), COUNT(DISTINCT id)       FROM `genbi-ecommerce.raw_thelook.order_items`
UNION ALL SELECT 'products',          COUNT(*), COUNT(DISTINCT id)       FROM `genbi-ecommerce.raw_thelook.products`
UNION ALL SELECT 'users',             COUNT(*), COUNT(DISTINCT id)       FROM `genbi-ecommerce.raw_thelook.users`
UNION ALL SELECT 'inventory_items',   COUNT(*), COUNT(DISTINCT id)       FROM `genbi-ecommerce.raw_thelook.inventory_items`;

-- Record: any table where rows != distinct_key is a grain surprise. Investigate before continuing.


-- ============================================================
-- 3. THE FAN-OUT RATIO  -> your headline number
-- ============================================================

WITH lines_per_order AS (
  SELECT order_id, COUNT(*) AS n_lines
  FROM `genbi-ecommerce.raw_thelook.order_items`
  GROUP BY order_id
)
SELECT
  COUNT(*)                                             AS n_orders,
  MIN(n_lines)                                         AS min_lines,
  APPROX_QUANTILES(n_lines, 100)[OFFSET(50)]           AS median_lines,
  APPROX_QUANTILES(n_lines, 100)[OFFSET(95)]           AS p95_lines,
  MAX(n_lines)                                         AS max_lines,
  ROUND(AVG(n_lines), 3)                               AS mean_lines
FROM lines_per_order;

-- mean_lines IS your expected_error_ratio for q301. Write it down.


-- Confirm it directly: the wrong query vs the right one.
SELECT
  (SELECT COUNT(*) FROM `genbi-ecommerce.raw_thelook.order_items`) AS truth_units,
  (SELECT SUM(o.num_of_item)
     FROM `genbi-ecommerce.raw_thelook.orders` o
     JOIN `genbi-ecommerce.raw_thelook.order_items` oi ON oi.order_id = o.order_id) AS distractor_units;

-- Also check: does orders.num_of_item actually equal the real line count?
SELECT
  COUNTIF(o.num_of_item = l.n_lines) AS agrees,
  COUNTIF(o.num_of_item != l.n_lines) AS disagrees
FROM `genbi-ecommerce.raw_thelook.orders` o
JOIN (SELECT order_id, COUNT(*) n_lines FROM `genbi-ecommerce.raw_thelook.order_items` GROUP BY order_id) l
  USING (order_id);


-- ============================================================
-- 4. STATUS CONFLICT  -> header vs line status
-- ============================================================

SELECT o.status AS order_status, oi.status AS line_status, COUNT(*) AS n
FROM `genbi-ecommerce.raw_thelook.orders` o
JOIN `genbi-ecommerce.raw_thelook.order_items` oi ON oi.order_id = o.order_id
GROUP BY 1, 2
ORDER BY n DESC;

-- Disagreement rate:
SELECT
  COUNT(*) AS total_lines,
  COUNTIF(o.status != oi.status) AS conflicting_lines,
  ROUND(100 * COUNTIF(o.status != oi.status) / COUNT(*), 2) AS pct_conflict
FROM `genbi-ecommerce.raw_thelook.orders` o
JOIN `genbi-ecommerce.raw_thelook.order_items` oi ON oi.order_id = o.order_id;

-- Are there orders with MIXED line statuses? (these have no single correct status)
SELECT COUNT(*) AS orders_with_mixed_line_status
FROM (
  SELECT order_id
  FROM `genbi-ecommerce.raw_thelook.order_items`
  GROUP BY order_id
  HAVING COUNT(DISTINCT status) > 1
);


-- ============================================================
-- 5. COST SOURCE  -> products.cost vs inventory_items.cost
-- ============================================================

SELECT
  COUNT(*) AS n,
  COUNTIF(ABS(p.cost - ii.cost) < 0.001) AS same_cost,
  COUNTIF(ABS(p.cost - ii.cost) >= 0.001) AS different_cost,
  ROUND(100 * COUNTIF(ABS(p.cost - ii.cost) >= 0.001) / COUNT(*), 2) AS pct_different,
  ROUND(AVG(ABS(p.cost - ii.cost)), 4) AS mean_abs_diff
FROM `genbi-ecommerce.raw_thelook.inventory_items` ii
JOIN `genbi-ecommerce.raw_thelook.products` p ON p.id = ii.product_id;

-- inventory_items also carries denormalised product fields.
-- Do they agree with the products table?
SELECT
  COUNTIF(ii.product_category != p.category) AS category_mismatch,
  COUNTIF(ii.product_brand    != p.brand)    AS brand_mismatch,
  COUNT(*) AS n
FROM `genbi-ecommerce.raw_thelook.inventory_items` ii
JOIN `genbi-ecommerce.raw_thelook.products` p ON p.id = ii.product_id;

-- Margin sanity: how many lines sold below cost?
SELECT
  COUNT(*) AS n_lines,
  COUNTIF(oi.sale_price < ii.cost) AS sold_below_cost,
  ROUND(100 * COUNTIF(oi.sale_price < ii.cost) / COUNT(*), 2) AS pct_below_cost
FROM `genbi-ecommerce.raw_thelook.order_items` oi
JOIN `genbi-ecommerce.raw_thelook.inventory_items` ii ON ii.id = oi.inventory_item_id;


-- ============================================================
-- 6. TIMESTAMPS  -> which one means "the sale happened", and future dates
-- ============================================================

SELECT
  MIN(created_at)  AS min_created,  MAX(created_at)  AS max_created,
  MIN(shipped_at)  AS min_shipped,  MAX(shipped_at)  AS max_shipped,
  MIN(delivered_at) AS min_delivered, MAX(delivered_at) AS max_delivered,
  MIN(returned_at) AS min_returned, MAX(returned_at) AS max_returned,
  CURRENT_TIMESTAMP() AS now
FROM `genbi-ecommerce.raw_thelook.order_items`;

-- How much of the data is in the future?
SELECT
  COUNT(*) AS total,
  COUNTIF(created_at > CURRENT_TIMESTAMP()) AS future_rows,
  ROUND(100 * COUNTIF(created_at > CURRENT_TIMESTAMP()) / COUNT(*), 2) AS pct_future,
  MAX(created_at) AS furthest_future
FROM `genbi-ecommerce.raw_thelook.order_items`;

-- Rows per year, so you can see the partial years at both ends:
SELECT EXTRACT(YEAR FROM created_at) AS yr, COUNT(*) AS n,
       ROUND(SUM(sale_price), 0) AS revenue
FROM `genbi-ecommerce.raw_thelook.order_items`
GROUP BY yr ORDER BY yr;

-- Do the timestamps ever go backwards? (delivered before shipped, etc.)
SELECT
  COUNTIF(shipped_at   < created_at) AS shipped_before_created,
  COUNTIF(delivered_at < shipped_at) AS delivered_before_shipped,
  COUNTIF(returned_at  < delivered_at) AS returned_before_delivered
FROM `genbi-ecommerce.raw_thelook.order_items`;


-- ============================================================
-- 7. NULLS AND ORPHANS  -> where LEFT JOIN is mandatory
-- ============================================================

SELECT
  COUNT(*) AS n,
  ROUND(100 * COUNTIF(inventory_item_id IS NULL) / COUNT(*), 2) AS pct_null_inventory_item,
  ROUND(100 * COUNTIF(product_id        IS NULL) / COUNT(*), 2) AS pct_null_product,
  ROUND(100 * COUNTIF(user_id           IS NULL) / COUNT(*), 2) AS pct_null_user,
  ROUND(100 * COUNTIF(sale_price        IS NULL) / COUNT(*), 2) AS pct_null_sale_price
FROM `genbi-ecommerce.raw_thelook.order_items`;

-- Referential integrity: do all FKs resolve?
SELECT
  (SELECT COUNT(*) FROM `genbi-ecommerce.raw_thelook.order_items` oi
     LEFT JOIN `genbi-ecommerce.raw_thelook.inventory_items` ii ON ii.id = oi.inventory_item_id
     WHERE ii.id IS NULL) AS orphan_inventory_items,
  (SELECT COUNT(*) FROM `genbi-ecommerce.raw_thelook.inventory_items` ii
     LEFT JOIN `genbi-ecommerce.raw_thelook.products` p ON p.id = ii.product_id
     WHERE p.id IS NULL) AS orphan_products,
  (SELECT COUNT(*) FROM `genbi-ecommerce.raw_thelook.order_items` oi
     LEFT JOIN `genbi-ecommerce.raw_thelook.users` u ON u.id = oi.user_id
     WHERE u.id IS NULL) AS orphan_users;

-- Products never sold (needed for the anti-join question q306):
SELECT COUNT(*) AS never_sold_products
FROM `genbi-ecommerce.raw_thelook.products` p
WHERE NOT EXISTS (
  SELECT 1 FROM `genbi-ecommerce.raw_thelook.inventory_items` ii
  JOIN `genbi-ecommerce.raw_thelook.order_items` oi ON oi.inventory_item_id = ii.id
  WHERE ii.product_id = p.id
);


-- ============================================================
-- 8. CATEGORICAL CARDINALITY  -> what dimensions are worth defining
-- ============================================================

SELECT 'category'   AS dim, COUNT(DISTINCT category)   AS n FROM `genbi-ecommerce.raw_thelook.products`
UNION ALL SELECT 'brand',      COUNT(DISTINCT brand)      FROM `genbi-ecommerce.raw_thelook.products`
UNION ALL SELECT 'department', COUNT(DISTINCT department) FROM `genbi-ecommerce.raw_thelook.products`
UNION ALL SELECT 'user_state', COUNT(DISTINCT state)      FROM `genbi-ecommerce.raw_thelook.users`
UNION ALL SELECT 'user_country', COUNT(DISTINCT country)  FROM `genbi-ecommerce.raw_thelook.users`
UNION ALL SELECT 'traffic_source', COUNT(DISTINCT traffic_source) FROM `genbi-ecommerce.raw_thelook.users`;

-- Distinct values of the status columns (needed for accepted_values tests):
SELECT status, COUNT(*) n FROM `genbi-ecommerce.raw_thelook.orders` GROUP BY 1 ORDER BY n DESC;
SELECT status, COUNT(*) n FROM `genbi-ecommerce.raw_thelook.order_items` GROUP BY 1 ORDER BY n DESC;

-- Watch for near-duplicate categorical values (whitespace, casing):
SELECT category, COUNT(*) n
FROM `genbi-ecommerce.raw_thelook.products`
WHERE category != TRIM(category) OR category != INITCAP(category)
GROUP BY 1 ORDER BY n DESC LIMIT 20;


-- ============================================================
-- 9. RETURNS  -> the net_revenue definition depends on this
-- ============================================================

SELECT
  COUNT(*) AS total_lines,
  COUNTIF(returned_at IS NOT NULL) AS returned_lines,
  ROUND(100 * COUNTIF(returned_at IS NOT NULL) / COUNT(*), 2) AS pct_returned,
  ROUND(SUM(sale_price), 0) AS gross_revenue,
  ROUND(SUM(IF(returned_at IS NULL, sale_price, 0)), 0) AS revenue_ex_returns
FROM `genbi-ecommerce.raw_thelook.order_items`;

-- Does status = 'Returned' always coincide with returned_at IS NOT NULL?
SELECT
  COUNTIF(status = 'Returned' AND returned_at IS NULL) AS returned_status_no_ts,
  COUNTIF(status != 'Returned' AND returned_at IS NOT NULL) AS ts_no_returned_status
FROM `genbi-ecommerce.raw_thelook.order_items`;

-- Orders with SOME but not all lines returned (partial returns):
SELECT COUNT(*) AS partially_returned_orders
FROM (
  SELECT order_id
  FROM `genbi-ecommerce.raw_thelook.order_items`
  GROUP BY order_id
  HAVING COUNTIF(returned_at IS NOT NULL) > 0
     AND COUNTIF(returned_at IS NULL) > 0
);


-- ============================================================
-- 10. CATEGORY SPANNING  -> makes q310 genuinely ambiguous
-- ============================================================

SELECT
  COUNT(*) AS n_orders,
  COUNTIF(n_categories > 1) AS multi_category_orders,
  ROUND(100 * COUNTIF(n_categories > 1) / COUNT(*), 2) AS pct_multi_category
FROM (
  SELECT oi.order_id, COUNT(DISTINCT p.category) AS n_categories
  FROM `genbi-ecommerce.raw_thelook.order_items` oi
  JOIN `genbi-ecommerce.raw_thelook.inventory_items` ii ON ii.id = oi.inventory_item_id
  JOIN `genbi-ecommerce.raw_thelook.products` p ON p.id = ii.product_id
  GROUP BY oi.order_id
);

-- ============================================================
-- 11. REDUNDANCY TRAPS  (visible only after the column inventory)
-- ============================================================

-- 11a. Do the two paths from order_items to products agree?
SELECT
  COUNT(*) AS n,
  COUNTIF(oi.product_id != ii.product_id) AS path_disagrees,
  ROUND(100 * COUNTIF(oi.product_id != ii.product_id) / COUNT(*), 4) AS pct
FROM `genbi-ecommerce.raw_thelook.order_items` oi
JOIN `genbi-ecommerce.raw_thelook.inventory_items` ii ON ii.id = oi.inventory_item_id;

-- 11b. Does the denormalised copy in inventory_items match products?
SELECT
  COUNTIF(ii.product_category != p.category)          AS category_mismatch,
  COUNTIF(ii.product_brand    != p.brand)             AS brand_mismatch,
  COUNTIF(ABS(ii.product_retail_price - p.retail_price) >= 0.001) AS retail_mismatch,
  COUNT(*) AS n
FROM `genbi-ecommerce.raw_thelook.inventory_items` ii
JOIN `genbi-ecommerce.raw_thelook.products` p ON p.id = ii.product_id;

-- 11c. Which timestamp means "the sale happened"?
--      order_items.created_at vs inventory_items.sold_at
SELECT
  COUNT(*) AS n,
  COUNTIF(ii.sold_at IS NULL) AS sold_at_null,
  COUNTIF(ii.sold_at != oi.created_at) AS timestamps_differ,
  ROUND(AVG(ABS(TIMESTAMP_DIFF(ii.sold_at, oi.created_at, SECOND))), 1) AS mean_abs_diff_sec
FROM `genbi-ecommerce.raw_thelook.order_items` oi
JOIN `genbi-ecommerce.raw_thelook.inventory_items` ii ON ii.id = oi.inventory_item_id;

-- 11d. orders.gender vs users.gender — two sources for one attribute
SELECT
  COUNT(*) AS n,
  COUNTIF(o.gender != u.gender) AS gender_disagrees
FROM `genbi-ecommerce.raw_thelook.orders` o
JOIN `genbi-ecommerce.raw_thelook.users` u ON u.id = o.user_id;

-- 11e. orders.returned_at vs order_items.returned_at
SELECT
  COUNTIF(o.returned_at IS NOT NULL AND oi.returned_at IS NULL) AS header_only,
  COUNTIF(o.returned_at IS NULL AND oi.returned_at IS NOT NULL) AS line_only,
  COUNT(*) AS n
FROM `genbi-ecommerce.raw_thelook.orders` o
JOIN `genbi-ecommerce.raw_thelook.order_items` oi ON oi.order_id = o.order_id;

-- 11f. order_items.user_id vs orders.user_id
SELECT COUNTIF(oi.user_id != o.user_id) AS user_id_disagrees, COUNT(*) AS n
FROM `genbi-ecommerce.raw_thelook.order_items` oi
JOIN `genbi-ecommerce.raw_thelook.orders` o ON o.order_id = oi.order_id;

-- 11g. Discounting: is sale_price ever below retail_price?
SELECT
  COUNT(*) AS n,
  COUNTIF(ABS(oi.sale_price - p.retail_price) >= 0.001) AS discounted_lines,
  ROUND(100 * COUNTIF(ABS(oi.sale_price - p.retail_price) >= 0.001) / COUNT(*), 2) AS pct_discounted
FROM `genbi-ecommerce.raw_thelook.order_items` oi
JOIN `genbi-ecommerce.raw_thelook.products` p ON p.id = oi.product_id;