-- q309 distractor: using inventory_items.sold_at (entirely NULL) instead of ordered_at
SELECT
  p.category,
  MAX(ii.sold_at) AS last_sale_at
FROM `genbi-ecommerce.raw_thelook.inventory_items` ii
JOIN `genbi-ecommerce.raw_thelook.products` p ON p.id = ii.product_id
GROUP BY p.category
ORDER BY last_sale_at DESC
