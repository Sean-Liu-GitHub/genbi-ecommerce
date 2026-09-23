-- q317: What is our net margin rate by department?
-- Trap: using products.cost instead of inventory_items.cost (unit_cost)
SELECT
  department,
  ROUND(SUM(line_margin) / NULLIF(SUM(sale_price), 0), 4) AS net_margin_rate
FROM `genbi-ecommerce.dbt_marts.fct_order_items`
WHERE line_status NOT IN ('Returned', 'Cancelled')
GROUP BY department
ORDER BY net_margin_rate DESC
