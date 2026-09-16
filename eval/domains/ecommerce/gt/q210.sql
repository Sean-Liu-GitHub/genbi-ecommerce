-- q210: What are the top 10 brands by units sold?
SELECT brand, COUNT(*) AS units_sold
FROM `genbi-ecommerce.dbt_marts.fct_order_items`
WHERE line_status NOT IN ('Returned', 'Cancelled')
GROUP BY brand
ORDER BY units_sold DESC
LIMIT 10
