-- q119: How many orders were returned?
SELECT COUNT(*) AS returned_orders
FROM `genbi-ecommerce.dbt_marts.fct_orders`
WHERE order_status = 'Returned'
