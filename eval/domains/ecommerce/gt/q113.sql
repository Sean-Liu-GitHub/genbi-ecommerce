-- q113: What country has the most customers?
SELECT country, COUNT(*) AS customer_count
FROM `genbi-ecommerce.dbt_marts.dim_users`
GROUP BY country
ORDER BY customer_count DESC
LIMIT 1
