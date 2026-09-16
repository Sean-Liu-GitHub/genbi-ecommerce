-- q234: What are the top 5 cities by number of customers?
SELECT city, COUNT(*) AS customer_count
FROM `genbi-ecommerce.dbt_marts.dim_users`
GROUP BY city
ORDER BY customer_count DESC
LIMIT 5
