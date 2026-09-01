select
    order_item_id,
    order_id,
    user_id,
    inventory_item_id,
    line_status,
    ordered_at,
    shipped_at,
    delivered_at,
    returned_at,
    sale_price,
    unit_cost,
    line_margin,
    category,
    brand,
    department,
    distribution_center
from {{ ref('int_order_items_enriched') }}