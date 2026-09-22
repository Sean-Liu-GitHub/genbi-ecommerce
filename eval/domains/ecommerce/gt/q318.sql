-- q318: What percentage of orders from each traffic source were returned?
SELECT
  u.traffic_source,
  ROUND(
    COUNT(DISTINCT CASE WHEN f.line_status = 'Returned' THEN f.order_id END)
    / CAST(COUNT(DISTINCT f.order_id) AS FLOAT64),
  4) AS return_rate
FROM `genbi-ecommerce.dbt_marts.fct_order_items` f
JOIN `genbi-ecommerce.dbt_marts.dim_users` u ON u.user_id = f.user_id
GROUP BY u.traffic_source
ORDER BY return_rate DESC
