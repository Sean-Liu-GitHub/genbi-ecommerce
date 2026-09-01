select
    id                as order_item_id,
    order_id,
    user_id,
    inventory_item_id,
    status            as line_status,
    created_at        as ordered_at,
    shipped_at,
    delivered_at,
    returned_at,
    sale_price
from {{ source('thelook', 'order_items') }}
where created_at <= '{{ var("as_of_date") }}'