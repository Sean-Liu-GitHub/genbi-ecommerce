select
    user_id,
    min(ordered_at)                                                                                as first_ordered_at,
    max(ordered_at)                                                                                as last_ordered_at,
    count(distinct order_id)                                                                       as lifetime_order_count,
    coalesce(
        max(ordered_at) >= timestamp_sub(timestamp('{{ var("as_of_date") }}'), interval 90 day),
        false
    )                                                                                              as is_active_user
from {{ ref('stg_orders') }}
group by 1