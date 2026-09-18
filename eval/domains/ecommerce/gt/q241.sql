-- q241: What was the average delivery time in days for completed orders in 2023?
-- Trap: 19.6% of lines have shipped_at < ordered_at (data quality issue)
SELECT ROUND(AVG(
  TIMESTAMP_DIFF(delivered_at, ordered_at, HOUR) / 24.0
), 2) AS avg_delivery_days
FROM `genbi-ecommerce.dbt_marts.fct_order_items`
WHERE line_status = 'Complete'
AND delivered_at IS NOT NULL
AND delivered_at >= ordered_at
AND EXTRACT(YEAR FROM ordered_at) = 2023
