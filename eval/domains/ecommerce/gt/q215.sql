-- q215: What is net revenue by distribution center?
SELECT
  distribution_center,
  ROUND(SUM(sale_price), 2) AS net_revenue
FROM `genbi-ecommerce.dbt_marts.fct_order_items`
WHERE line_status NOT IN ('Returned', 'Cancelled')
GROUP BY distribution_center
ORDER BY net_revenue DESC
