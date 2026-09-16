-- q204: How many units did we sell in Q4 2023?
SELECT COUNT(*) AS units_sold
FROM `genbi-ecommerce.dbt_marts.fct_order_items`
WHERE ordered_at >= '2023-10-01' AND ordered_at < '2024-01-01'
AND line_status NOT IN ('Returned', 'Cancelled')
