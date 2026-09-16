-- q205: What is revenue by department?
SELECT
  department,
  ROUND(SUM(sale_price), 2) AS net_revenue
FROM `genbi-ecommerce.dbt_marts.fct_order_items`
WHERE line_status NOT IN ('Returned', 'Cancelled')
GROUP BY department
ORDER BY net_revenue DESC
