-- q206: Which brand has the highest net revenue?
SELECT brand, ROUND(SUM(sale_price), 2) AS net_revenue
FROM `genbi-ecommerce.dbt_marts.fct_order_items`
WHERE line_status NOT IN ('Returned', 'Cancelled')
GROUP BY brand
ORDER BY net_revenue DESC
LIMIT 1
