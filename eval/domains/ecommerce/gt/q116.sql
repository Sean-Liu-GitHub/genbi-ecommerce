-- q116: How many unique customers have placed an order?
SELECT COUNT(DISTINCT user_id) AS customer_count
FROM `genbi-ecommerce.dbt_marts.fct_order_items`
