-- q208: How many orders per month in 2023?
SELECT
  FORMAT_TIMESTAMP('%Y-%m', ordered_at) AS month,
  COUNT(DISTINCT order_id) AS order_count
FROM `genbi-ecommerce.dbt_marts.fct_order_items`
WHERE EXTRACT(YEAR FROM ordered_at) = 2023
GROUP BY month
ORDER BY month
