select
    id                as inventory_item_id,
    product_id,
    created_at        as inventory_created_at,
    cost
from {{ source('thelook', 'inventory_items') }}