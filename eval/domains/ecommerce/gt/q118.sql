-- q118: What is the average number of items per order?
SELECT ROUND(
  CAST(COUNT(*) AS FLOAT64) / COUNT(DISTINCT order_id),
2) AS avg_items_per_order
FROM `genbi-ecommerce.dbt_marts.fct_order_items`
