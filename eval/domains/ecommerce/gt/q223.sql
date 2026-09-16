-- q223: How many orders did we get from each traffic source?
SELECT
  u.traffic_source,
  COUNT(DISTINCT f.order_id) AS order_count
FROM `genbi-ecommerce.dbt_marts.fct_order_items` f
JOIN `genbi-ecommerce.dbt_marts.dim_users` u ON u.user_id = f.user_id
GROUP BY u.traffic_source
ORDER BY order_count DESC
