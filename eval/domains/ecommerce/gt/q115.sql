-- q115: What is the most popular product category by units sold?
SELECT category, COUNT(*) AS units_sold
FROM `genbi-ecommerce.dbt_marts.fct_order_items`
WHERE line_status NOT IN ('Returned', 'Cancelled')
GROUP BY category
ORDER BY units_sold DESC
LIMIT 1
