-- q110: What is our total gross revenue?
SELECT ROUND(SUM(sale_price), 2) AS gross_revenue
FROM `genbi-ecommerce.dbt_marts.fct_order_items`
