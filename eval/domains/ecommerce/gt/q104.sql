-- q104: What are our product departments?
SELECT DISTINCT department
FROM `genbi-ecommerce.dbt_marts.dim_products`
ORDER BY department
