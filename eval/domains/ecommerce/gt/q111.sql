-- q111: What is our average order value?
SELECT ROUND(
  SUM(CASE WHEN line_status NOT IN ('Returned', 'Cancelled') THEN sale_price END)
  / COUNT(DISTINCT order_id),
2) AS average_order_value
FROM `genbi-ecommerce.dbt_marts.fct_order_items`
