-- q106: How many distribution centers do we have?
SELECT COUNT(*) AS dc_count
FROM `genbi-ecommerce.dbt_marts.dim_distribution_centers`
