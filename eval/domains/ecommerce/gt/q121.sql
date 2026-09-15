-- q121: What is the most expensive product by retail price?
SELECT product_name, retail_price
FROM `genbi-ecommerce.dbt_marts.dim_products`
ORDER BY retail_price DESC
LIMIT 1
