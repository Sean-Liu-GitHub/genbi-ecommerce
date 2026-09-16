-- q207: What is the return rate by product category?
SELECT
  category,
  ROUND(COUNTIF(line_status = 'Returned') / CAST(COUNT(*) AS FLOAT64), 4) AS return_rate
FROM `genbi-ecommerce.dbt_marts.fct_order_items`
GROUP BY category
ORDER BY return_rate DESC
