-- q302: What was total net revenue by product category in 2023?
SELECT
  category,
  ROUND(SUM(sale_price), 2) AS net_revenue
FROM `genbi-ecommerce.dbt_marts.fct_order_items`
WHERE line_status NOT IN ('Returned', 'Cancelled')
AND EXTRACT(YEAR FROM ordered_at) = 2023
GROUP BY category
ORDER BY net_revenue DESC
