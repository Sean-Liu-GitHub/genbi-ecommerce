-- q242: What are the top 5 brands by net margin in the Women's department?
SELECT
  brand,
  ROUND(SUM(line_margin), 2) AS net_margin
FROM `genbi-ecommerce.dbt_marts.fct_order_items`
WHERE line_status NOT IN ('Returned', 'Cancelled')
AND department = 'Women'
GROUP BY brand
ORDER BY net_margin DESC
LIMIT 5
