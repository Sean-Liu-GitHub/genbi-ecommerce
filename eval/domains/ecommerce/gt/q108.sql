-- q108: How many order lines are there in total?
SELECT COUNT(*) AS total_lines
FROM `genbi-ecommerce.dbt_marts.fct_order_items`
