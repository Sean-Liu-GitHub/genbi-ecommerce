-- q236 distractor: counting all lines including Returned and Cancelled
SELECT
  category,
  COUNT(*) AS units_sold
FROM `genbi-ecommerce.dbt_marts.fct_order_items`
GROUP BY category
ORDER BY units_sold DESC
