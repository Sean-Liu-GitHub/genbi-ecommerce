-- q209: What is net revenue by month in 2024?
SELECT
  FORMAT_TIMESTAMP('%Y-%m', ordered_at) AS month,
  ROUND(SUM(sale_price), 2) AS net_revenue
FROM `genbi-ecommerce.dbt_marts.fct_order_items`
WHERE line_status NOT IN ('Returned', 'Cancelled')
  AND EXTRACT(YEAR FROM ordered_at) = 2024
GROUP BY month
ORDER BY month
