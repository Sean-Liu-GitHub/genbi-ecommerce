-- q224: What is net revenue for the Allegra K brand?
SELECT ROUND(SUM(sale_price), 2) AS net_revenue
FROM `genbi-ecommerce.dbt_marts.fct_order_items`
WHERE line_status NOT IN ('Returned', 'Cancelled')
  AND brand = 'Allegra K'
