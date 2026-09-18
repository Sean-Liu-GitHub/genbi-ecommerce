-- q250: Which categories have the highest cancellation rate?
SELECT
  category,
  ROUND(COUNTIF(line_status = 'Cancelled') / CAST(COUNT(*) AS FLOAT64), 4) AS cancellation_rate
FROM `genbi-ecommerce.dbt_marts.fct_order_items`
GROUP BY category
ORDER BY cancellation_rate DESC
