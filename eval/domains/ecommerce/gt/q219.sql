-- q219: What are the bottom 5 categories by net revenue?
SELECT
  category,
  ROUND(SUM(sale_price), 2) AS net_revenue
FROM `genbi-ecommerce.dbt_marts.fct_order_items`
WHERE line_status NOT IN ('Returned', 'Cancelled')
GROUP BY category
ORDER BY net_revenue ASC
LIMIT 5
