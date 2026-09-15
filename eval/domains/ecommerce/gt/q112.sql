-- q112: How many brands do we sell?
SELECT COUNT(DISTINCT brand) AS brand_count
FROM `genbi-ecommerce.dbt_marts.dim_products`
