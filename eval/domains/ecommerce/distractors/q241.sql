-- q241 distractor: measuring ship-to-delivery instead of order-to-delivery
SELECT ROUND(AVG(
  TIMESTAMP_DIFF(delivered_at, shipped_at, HOUR) / 24.0
), 2) AS avg_delivery_days
FROM `genbi-ecommerce.dbt_marts.fct_order_items`
WHERE line_status = 'Complete'
AND delivered_at IS NOT NULL
AND EXTRACT(YEAR FROM ordered_at) = 2023
