-- q315: What is the total net revenue per customer?
-- Trap: joining fct_orders to fct_order_items would fan out
SELECT
  user_id,
  ROUND(SUM(sale_price), 2) AS total_revenue
FROM `genbi-ecommerce.dbt_marts.fct_order_items`
WHERE line_status NOT IN ('Returned', 'Cancelled')
GROUP BY user_id
ORDER BY total_revenue DESC
