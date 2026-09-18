-- q246: What are monthly units sold by department in 2023?
SELECT
  department,
  FORMAT_TIMESTAMP('%Y-%m', ordered_at) AS month,
  COUNT(*) AS units_sold
FROM `genbi-ecommerce.dbt_marts.fct_order_items`
WHERE EXTRACT(YEAR FROM ordered_at) = 2023
AND line_status NOT IN ('Returned', 'Cancelled')
GROUP BY department, month
ORDER BY department, month
