-- q231: Which country has the highest average order value?
SELECT
  u.country,
  ROUND(
    SUM(CASE WHEN f.line_status NOT IN ('Returned', 'Cancelled') THEN f.sale_price END)
    / COUNT(DISTINCT f.order_id),
  2) AS average_order_value
FROM `genbi-ecommerce.dbt_marts.fct_order_items` f
JOIN `genbi-ecommerce.dbt_marts.dim_users` u ON u.user_id = f.user_id
GROUP BY u.country
ORDER BY average_order_value DESC
LIMIT 1
