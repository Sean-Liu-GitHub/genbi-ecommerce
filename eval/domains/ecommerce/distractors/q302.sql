-- q302 distractor: fan-out via joining fct_orders.gross_revenue to line-grain categories
SELECT
  oi.category,
  ROUND(SUM(o.gross_revenue), 2) AS revenue
FROM `genbi-ecommerce.dbt_marts.fct_orders` o
JOIN `genbi-ecommerce.dbt_marts.fct_order_items` oi ON oi.order_id = o.order_id
WHERE EXTRACT(YEAR FROM o.ordered_at) = 2023
GROUP BY oi.category
ORDER BY revenue DESC
