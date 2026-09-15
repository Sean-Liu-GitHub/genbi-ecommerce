-- q107: What are the possible order statuses?
SELECT DISTINCT line_status
FROM `genbi-ecommerce.dbt_marts.fct_order_items`
ORDER BY line_status
