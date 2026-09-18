-- q249: How many orders contain items from more than one category?
SELECT COUNT(*) AS multi_category_orders
FROM (
  SELECT order_id
  FROM `genbi-ecommerce.dbt_marts.fct_order_items`
  GROUP BY order_id
  HAVING COUNT(DISTINCT category) > 1
)
