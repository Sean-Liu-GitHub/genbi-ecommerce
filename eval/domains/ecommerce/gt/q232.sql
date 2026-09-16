-- q232: How many new customers did we acquire each month in 2023?
SELECT
  FORMAT_TIMESTAMP('%Y-%m', signed_up_at) AS month,
  COUNT(*) AS new_customers
FROM `genbi-ecommerce.dbt_marts.dim_users`
WHERE EXTRACT(YEAR FROM signed_up_at) = 2023
GROUP BY month
ORDER BY month
