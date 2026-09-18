-- q239: What is net revenue by category for orders placed in Q1 2024?
SELECT
  category,
  ROUND(SUM(sale_price), 2) AS net_revenue
FROM `genbi-ecommerce.dbt_marts.fct_order_items`
WHERE line_status NOT IN ('Returned', 'Cancelled')
AND ordered_at >= '2024-01-01' AND ordered_at < '2024-04-01'
GROUP BY category
ORDER BY net_revenue DESC
