select
    order_id,
    user_id,
    status          as order_status,
    created_at      as ordered_at,
    shipped_at,
    delivered_at,
    num_of_item
from {{ source('thelook', 'orders') }}
where created_at <= '{{ var("as_of_date") }}'