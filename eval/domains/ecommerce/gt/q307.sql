-- q307: How many orders per distribution center?
SELECT
  distribution_center,
  COUNT(DISTINCT order_id) AS order_count
FROM `genbi-ecommerce.dbt_marts.fct_order_items`
GROUP BY distribution_center
ORDER BY order_count DESC
