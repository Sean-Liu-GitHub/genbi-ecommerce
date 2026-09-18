-- q253: What is the net revenue by brand and department combination?
SELECT
  brand,
  department,
  ROUND(SUM(sale_price), 2) AS net_revenue
FROM `genbi-ecommerce.dbt_marts.fct_order_items`
WHERE line_status NOT IN ('Returned', 'Cancelled')
GROUP BY brand, department
ORDER BY net_revenue DESC
