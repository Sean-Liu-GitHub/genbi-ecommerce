-- q243: How many unique customers ordered from each product category in 2023?
SELECT
  category,
  COUNT(DISTINCT user_id) AS unique_customers
FROM `genbi-ecommerce.dbt_marts.fct_order_items`
WHERE EXTRACT(YEAR FROM ordered_at) = 2023
GROUP BY category
ORDER BY unique_customers DESC
