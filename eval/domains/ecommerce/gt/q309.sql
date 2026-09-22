-- q309: When was the last sale for each product category?
-- Trap: an LLM might use inventory_items.sold_at which is entirely NULL
SELECT
  category,
  MAX(ordered_at) AS last_sale_at
FROM `genbi-ecommerce.dbt_marts.fct_order_items`
WHERE line_status NOT IN ('Returned', 'Cancelled')
GROUP BY category
ORDER BY last_sale_at DESC
