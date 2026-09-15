-- q123: How many cancelled orders do we have?
SELECT COUNT(*) AS cancelled_orders
FROM `genbi-ecommerce.dbt_marts.fct_orders`
WHERE order_status = 'Cancelled'
