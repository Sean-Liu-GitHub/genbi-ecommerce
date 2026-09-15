-- q125: What is the total cost of goods sold?
SELECT ROUND(SUM(unit_cost), 2) AS net_cost
FROM `genbi-ecommerce.dbt_marts.fct_order_items`
WHERE line_status NOT IN ('Returned', 'Cancelled')
