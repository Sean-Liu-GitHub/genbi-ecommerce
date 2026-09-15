-- q105: How many products do we carry?
SELECT COUNT(*) AS product_count
FROM `genbi-ecommerce.dbt_marts.dim_products`
