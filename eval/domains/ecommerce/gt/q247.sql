-- q247: Which brands had declining net revenue from 2022 to 2023?
WITH brand_yearly AS (
  SELECT
    brand,
    EXTRACT(YEAR FROM ordered_at) AS yr,
    SUM(sale_price) AS net_revenue
  FROM `genbi-ecommerce.dbt_marts.fct_order_items`
  WHERE line_status NOT IN ('Returned', 'Cancelled')
  AND EXTRACT(YEAR FROM ordered_at) IN (2022, 2023)
  GROUP BY brand, yr
)
SELECT
  a.brand,
  ROUND(a.net_revenue, 2) AS revenue_2022,
  ROUND(b.net_revenue, 2) AS revenue_2023
FROM brand_yearly a
JOIN brand_yearly b ON a.brand = b.brand AND a.yr = 2022 AND b.yr = 2023
WHERE b.net_revenue < a.net_revenue
ORDER BY (a.net_revenue - b.net_revenue) DESC
