-- q251: What is the average days between a customer's first and second order?
WITH ordered AS (
  SELECT
    user_id,
    ordered_at,
    ROW_NUMBER() OVER (PARTITION BY user_id ORDER BY ordered_at) AS rn
  FROM (
    SELECT DISTINCT user_id, order_id, ordered_at
    FROM `genbi-ecommerce.dbt_marts.fct_order_items`
  )
)
SELECT ROUND(AVG(
  TIMESTAMP_DIFF(o2.ordered_at, o1.ordered_at, HOUR) / 24.0
), 2) AS avg_days_to_second_order
FROM ordered o1
JOIN ordered o2 ON o1.user_id = o2.user_id AND o1.rn = 1 AND o2.rn = 2
