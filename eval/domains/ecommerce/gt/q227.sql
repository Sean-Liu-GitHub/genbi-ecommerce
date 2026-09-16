-- q227: What is net revenue by gender?
SELECT
  u.gender,
  ROUND(SUM(f.sale_price), 2) AS net_revenue
FROM `genbi-ecommerce.dbt_marts.fct_order_items` f
JOIN `genbi-ecommerce.dbt_marts.dim_users` u ON u.user_id = f.user_id
WHERE f.line_status NOT IN ('Returned', 'Cancelled')
GROUP BY u.gender
ORDER BY net_revenue DESC
