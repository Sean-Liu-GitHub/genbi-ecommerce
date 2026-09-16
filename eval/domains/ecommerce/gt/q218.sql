-- q218: How many orders were placed per quarter in 2023?
SELECT
  EXTRACT(QUARTER FROM ordered_at) AS quarter,
  COUNT(DISTINCT order_id) AS order_count
FROM `genbi-ecommerce.dbt_marts.fct_order_items`
WHERE EXTRACT(YEAR FROM ordered_at) = 2023
GROUP BY quarter
ORDER BY quarter
