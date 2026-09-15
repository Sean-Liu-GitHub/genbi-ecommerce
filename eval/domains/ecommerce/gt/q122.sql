-- q122: What is our net margin rate?
SELECT ROUND(
  SUM(line_margin) / NULLIF(SUM(sale_price), 0),
4) AS margin_rate
FROM `genbi-ecommerce.dbt_marts.fct_order_items`
WHERE line_status NOT IN ('Returned', 'Cancelled')
