-- q303 distractor: using products.retail_price instead of inventory_items.cost for margin
SELECT
  oi.brand,
  ROUND(SUM(oi.sale_price - p.retail_price), 2) AS gross_margin
FROM `genbi-ecommerce.dbt_marts.fct_order_items` oi
JOIN `genbi-ecommerce.dbt_marts.dim_products` p ON p.product_id = oi.inventory_item_id
GROUP BY oi.brand
ORDER BY gross_margin DESC
