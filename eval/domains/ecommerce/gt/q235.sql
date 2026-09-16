-- q235: What is net revenue by order status?
SELECT
  line_status,
  ROUND(SUM(sale_price), 2) AS revenue
FROM `genbi-ecommerce.dbt_marts.fct_order_items`
GROUP BY line_status
ORDER BY revenue DESC
