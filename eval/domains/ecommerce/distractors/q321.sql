-- q321 distractor: using orders.num_of_item which fans out when joined to line grain
SELECT
  oi.category,
  ROUND(AVG(o.num_of_item), 2) AS avg_items_per_order
FROM `genbi-ecommerce.dbt_marts.fct_orders` o
JOIN `genbi-ecommerce.dbt_marts.fct_order_items` oi ON oi.order_id = o.order_id
GROUP BY oi.category
ORDER BY avg_items_per_order DESC
