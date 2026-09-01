select
    oi.order_item_id,
    oi.order_id,
    oi.user_id,
    oi.inventory_item_id,
    oi.line_status,
    oi.ordered_at,
    oi.shipped_at,
    oi.delivered_at,
    oi.returned_at,
    oi.sale_price,
    ii.cost                    as unit_cost,
    oi.sale_price - ii.cost    as line_margin,
    p.category,
    p.brand,
    p.department,
    dc.name                    as distribution_center
from {{ ref('stg_order_items') }} oi
left join {{ ref('stg_inventory_items') }} ii
    on ii.inventory_item_id = oi.inventory_item_id
left join {{ ref('stg_products') }} p
    on p.product_id = ii.product_id
left join {{ ref('stg_distribution_centers') }} dc
    on dc.id = p.distribution_center_id