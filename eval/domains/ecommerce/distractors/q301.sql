-- q301 distractor: fan-out via SUM(num_of_item) after joining orders to order_items
SELECT SUM(o.num_of_item) AS units_sold
FROM `genbi-ecommerce.dbt_marts.fct_orders` o
JOIN `genbi-ecommerce.dbt_marts.fct_order_items` oi ON oi.order_id = o.order_id
WHERE EXTRACT(YEAR FROM o.ordered_at) = 2023
AND oi.line_status NOT IN ('Returned', 'Cancelled')
