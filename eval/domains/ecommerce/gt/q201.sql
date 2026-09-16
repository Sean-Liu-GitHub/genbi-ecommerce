-- q201: What was our net revenue in 2023?
SELECT ROUND(SUM(sale_price), 2) AS net_revenue
FROM `genbi-ecommerce.dbt_marts.fct_order_items`
WHERE line_status NOT IN ('Returned', 'Cancelled')
  AND EXTRACT(YEAR FROM ordered_at) = 2023
