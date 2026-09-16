-- q222: What percentage of customers are from the United States?
SELECT ROUND(
  COUNTIF(country = 'United States') / CAST(COUNT(*) AS FLOAT64),
4) AS us_pct
FROM `genbi-ecommerce.dbt_marts.dim_users`
