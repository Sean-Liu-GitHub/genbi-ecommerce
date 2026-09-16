-- q214: How many active users do we have?
SELECT COUNT(*) AS active_users
FROM `genbi-ecommerce.dbt_marts.fct_user_activity`
WHERE is_active_user = TRUE
