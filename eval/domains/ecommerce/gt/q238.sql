-- q238: What is the return rate by brand for the top 10 brands by gross revenue?
WITH top_brands AS (
  SELECT brand,
    SUM(sale_price) AS gross_revenue
  FROM `genbi-ecommerce.dbt_marts.fct_order_items`
  GROUP BY brand
  ORDER BY net_revenue DESC
  LIMIT 10
)
SELECT
  f.brand,
  ROUND(COUNTIF(f.line_status = 'Returned') / CAST(COUNT(*) AS FLOAT64), 4) AS return_rate
FROM `genbi-ecommerce.dbt_marts.fct_order_items` f
WHERE f.brand IN (SELECT brand FROM top_brands)
GROUP BY f.brand
ORDER BY return_rate DESC
