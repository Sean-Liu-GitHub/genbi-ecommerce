-- q216: What was gross margin by category in 2023?
SELECT
  category,
  ROUND(SUM(line_margin), 2) AS gross_margin
FROM `genbi-ecommerce.dbt_marts.fct_order_items`
WHERE EXTRACT(YEAR FROM ordered_at) = 2023
GROUP BY category
ORDER BY gross_margin DESC
