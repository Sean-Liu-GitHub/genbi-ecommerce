-- q315 distractor: fan-out by joining fct_orders to fct_order_items then summing order-level revenue
SELECT
  o.user_id,
  ROUND(SUM(o.net_revenue), 2) AS total_revenue
FROM `genbi-ecommerce.dbt_marts.fct_orders` o
JOIN `genbi-ecommerce.dbt_marts.fct_order_items` oi ON oi.order_id = o.order_id
GROUP BY o.user_id
ORDER BY total_revenue DESC
