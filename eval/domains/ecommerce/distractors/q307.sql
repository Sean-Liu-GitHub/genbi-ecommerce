-- q307 distractor: fan-out via joining fct_orders to fct_order_items for order count by DC
SELECT
  oi.distribution_center,
  COUNT(*) AS order_count
FROM `genbi-ecommerce.dbt_marts.fct_orders` o
JOIN `genbi-ecommerce.dbt_marts.fct_order_items` oi ON oi.order_id = o.order_id
GROUP BY oi.distribution_center
ORDER BY order_count DESC
