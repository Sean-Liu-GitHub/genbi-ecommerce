-- q236: How many items were sold in each product category?
SELECT
  category,
  COUNT(*) AS units_sold
FROM `genbi-ecommerce.dbt_marts.fct_order_items`
WHERE line_status NOT IN ('Returned', 'Cancelled')
GROUP BY category
ORDER BY units_sold DESC
