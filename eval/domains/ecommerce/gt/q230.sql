-- q230: What is the year-over-year net revenue growth from 2022 to 2023?
WITH yearly AS (
  SELECT
    EXTRACT(YEAR FROM ordered_at) AS yr,
    SUM(sale_price) AS net_revenue
  FROM `genbi-ecommerce.dbt_marts.fct_order_items`
  WHERE line_status NOT IN ('Returned', 'Cancelled')
    AND EXTRACT(YEAR FROM ordered_at) IN (2022, 2023)
  GROUP BY yr
)
SELECT ROUND(
  (net_revenue - LAG(net_revenue) OVER (ORDER BY yr))
  / NULLIF(LAG(net_revenue) OVER (ORDER BY yr), 0),
4) AS yoy_growth
FROM yearly
QUALIFY yr = 2023
