-- q305 distractor: using dim_products.retail_price as cost instead of fct_order_items.unit_cost
SELECT
  p.category,
  ROUND(AVG(p.retail_price), 2) AS avg_unit_cost
FROM `genbi-ecommerce.dbt_marts.dim_products` p
GROUP BY p.category
ORDER BY avg_unit_cost DESC
