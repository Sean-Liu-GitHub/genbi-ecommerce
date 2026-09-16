-- q211: How many customers signed up in 2023?
SELECT COUNT(*) AS signups
FROM `genbi-ecommerce.dbt_marts.dim_users`
WHERE EXTRACT(YEAR FROM signed_up_at) = 2023
