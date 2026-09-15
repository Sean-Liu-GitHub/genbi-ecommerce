-- q103: How many product categories are there?
SELECT COUNT(DISTINCT category) AS category_count
FROM `genbi-ecommerce.dbt_marts.dim_products`
