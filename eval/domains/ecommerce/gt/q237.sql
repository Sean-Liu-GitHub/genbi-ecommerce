-- q237: Which product categories had no sales in December 2023?
WITH dec_categories AS (
  SELECT DISTINCT category
  FROM `genbi-ecommerce.dbt_marts.fct_order_items`
  WHERE ordered_at >= '2023-12-01' AND ordered_at < '2024-01-01'
  AND line_status NOT IN ('Returned', 'Cancelled')
)
SELECT category
FROM (SELECT DISTINCT category FROM `genbi-ecommerce.dbt_marts.fct_order_items`) all_cat
WHERE category NOT IN (SELECT category FROM dec_categories)
ORDER BY category
