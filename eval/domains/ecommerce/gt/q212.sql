-- q212: What is net revenue for the Women's department in 2023?
SELECT ROUND(SUM(sale_price), 2) AS net_revenue
FROM `genbi-ecommerce.dbt_marts.fct_order_items`
WHERE line_status NOT IN ('Returned', 'Cancelled')
  AND department = 'Women'
  AND EXTRACT(YEAR FROM ordered_at) = 2023
