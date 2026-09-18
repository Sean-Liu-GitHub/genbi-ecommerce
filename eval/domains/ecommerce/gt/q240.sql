-- q240: Which distribution center has the highest net margin rate?
SELECT
  distribution_center,
  ROUND(SUM(line_margin) / NULLIF(SUM(sale_price), 0), 4) AS net_margin_rate
FROM `genbi-ecommerce.dbt_marts.fct_order_items`
WHERE line_status NOT IN ('Returned', 'Cancelled')
GROUP BY distribution_center
ORDER BY net_margin_rate DESC
LIMIT 1
