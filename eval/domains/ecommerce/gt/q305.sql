-- q305: What is the average cost per unit sold by category?
SELECT
  category,
  ROUND(AVG(unit_cost), 2) AS avg_unit_cost
FROM `genbi-ecommerce.dbt_marts.fct_order_items`
WHERE line_status NOT IN ('Returned', 'Cancelled')
GROUP BY category
ORDER BY avg_unit_cost DESC
