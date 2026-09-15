-- q117: What is our total net margin?
SELECT ROUND(SUM(line_margin), 2) AS net_margin
FROM `genbi-ecommerce.dbt_marts.fct_order_items`
WHERE line_status NOT IN ('Returned', 'Cancelled')
