-- q124: What are the names of our distribution centers?
SELECT name AS distribution_center
FROM `genbi-ecommerce.dbt_marts.dim_distribution_centers`
ORDER BY name
