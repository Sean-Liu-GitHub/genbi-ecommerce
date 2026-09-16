-- q203: What is net revenue by product category?
SELECT
  category,
  ROUND(SUM(sale_price), 2) AS net_revenue
FROM `genbi-ecommerce.dbt_marts.fct_order_items`
WHERE line_status NOT IN ('Returned', 'Cancelled')
GROUP BY category
ORDER BY net_revenue DESC
