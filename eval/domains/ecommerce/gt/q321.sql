-- q321: What is the average number of items per order by category?
-- Trap: using orders.num_of_item would fan out
SELECT
  category,
  ROUND(CAST(COUNT(*) AS FLOAT64) / COUNT(DISTINCT order_id), 2) AS avg_items_per_order
FROM `genbi-ecommerce.dbt_marts.fct_order_items`
GROUP BY category
ORDER BY avg_items_per_order DESC
