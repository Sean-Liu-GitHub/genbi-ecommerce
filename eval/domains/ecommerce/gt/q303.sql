-- q303: What is our gross margin by brand?
SELECT
  brand,
  ROUND(SUM(line_margin), 2) AS gross_margin
FROM `genbi-ecommerce.dbt_marts.fct_order_items`
GROUP BY brand
ORDER BY gross_margin DESC
