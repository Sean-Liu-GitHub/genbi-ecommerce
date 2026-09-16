-- q220: How many orders were cancelled in 2023?
SELECT COUNT(DISTINCT order_id) AS cancelled_orders
FROM `genbi-ecommerce.dbt_marts.fct_order_items`
WHERE line_status = 'Cancelled' AND EXTRACT(YEAR FROM ordered_at) = 2023
