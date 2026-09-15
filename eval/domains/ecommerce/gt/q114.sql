-- q114: What is our overall return rate?
SELECT ROUND(
  COUNTIF(line_status = 'Returned') / COUNT(*),
4) AS return_rate
FROM `genbi-ecommerce.dbt_marts.fct_order_items`
