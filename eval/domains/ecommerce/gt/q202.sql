-- q202: How many orders were placed in January 2024?
SELECT COUNT(DISTINCT order_id) AS order_count
FROM `genbi-ecommerce.dbt_marts.fct_order_items`
WHERE ordered_at >= '2024-01-01' AND ordered_at < '2024-02-01'
