select
    o.order_id,
    o.user_id,
    o.ordered_at,
    o.order_status,
    count(ie.order_item_id)                                                                                  as line_count,
    coalesce(sum(ie.sale_price), 0)                                                                          as gross_revenue,
    coalesce(sum(case when ie.line_status not in ('Returned', 'Cancelled') then ie.sale_price end), 0)       as net_revenue,
    coalesce(sum(ie.unit_cost), 0)                                                                           as total_cost,
    coalesce(sum(case when ie.line_status not in ('Returned', 'Cancelled') then ie.unit_cost end), 0)        as net_cost,
    countif(ie.line_status = 'Returned') > 0                                                                 as is_returned
from {{ ref('stg_orders') }} o
left join {{ ref('int_order_items_enriched') }} ie
    on ie.order_id = o.order_id
group by 1, 2, 3, 4