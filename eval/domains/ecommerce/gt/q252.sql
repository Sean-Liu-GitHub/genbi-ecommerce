-- q252: What percentage of net revenue comes from the top 10 brands by net revenue?
WITH brand_rev AS (
  SELECT brand,
    SUM(sale_price) AS net_revenue
  FROM `genbi-ecommerce.dbt_marts.fct_order_items`
  WHERE line_status NOT IN ('Returned', 'Cancelled')
  GROUP BY brand
  ORDER BY net_revenue DESC
  LIMIT 10
)
SELECT ROUND(
  (SELECT SUM(net_revenue) FROM brand_rev)
  / (SELECT SUM(sale_price)
     FROM `genbi-ecommerce.dbt_marts.fct_order_items`
     WHERE line_status NOT IN ('Returned', 'Cancelled')),
4) AS top10_pct