-- q217: Which state has the most customers?
SELECT state, COUNT(*) AS customer_count
FROM `genbi-ecommerce.dbt_marts.dim_users`
GROUP BY state
ORDER BY customer_count DESC
LIMIT 1
