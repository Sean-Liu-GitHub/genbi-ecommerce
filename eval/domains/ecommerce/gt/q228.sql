-- q228: How many orders shipped in February 2024?
SELECT COUNT(DISTINCT order_id) AS shipped_orders
FROM `genbi-ecommerce.dbt_marts.fct_order_items`
WHERE line_status = 'Shipped'
AND shipped_at >= '2024-02-01' AND shipped_at < '2024-03-01'
