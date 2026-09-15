-- q120: What traffic source brings in the most customers?
SELECT traffic_source, COUNT(*) AS customer_count
FROM `genbi-ecommerce.dbt_marts.dim_users`
GROUP BY traffic_source
ORDER BY customer_count DESC
LIMIT 1
