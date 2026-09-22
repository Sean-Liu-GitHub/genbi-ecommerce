-- q317 distractor: computing margin using dim_products.retail_price as cost
SELECT
  oi.department,
  ROUND(
    SUM(CASE WHEN oi.line_status NOT IN ('Returned', 'Cancelled') THEN oi.sale_price - p.retail_price END)
    / NULLIF(SUM(CASE WHEN oi.line_status NOT IN ('Returned', 'Cancelled') THEN oi.sale_price END), 0),
  4) AS margin_rate
FROM `genbi-ecommerce.dbt_marts.fct_order_items` oi
JOIN `genbi-ecommerce.dbt_marts.dim_products` p ON p.product_id = oi.inventory_item_id
GROUP BY oi.department
ORDER BY margin_rate DESC
