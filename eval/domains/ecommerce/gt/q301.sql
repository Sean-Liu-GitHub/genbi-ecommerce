-- q301: How many items did we sell in 2023?
SELECT COUNT(*) AS units_sold
FROM `genbi-ecommerce.dbt_marts.fct_order_items`
WHERE line_status NOT IN ('Returned', 'Cancelled')
AND EXTRACT(YEAR FROM ordered_at) = 2023
