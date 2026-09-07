-- Fan-out canary: fct_orders must have exactly one row per distinct order_id
-- present in fct_order_items (fct_orders excludes orders with zero lines,
-- e.g. orders whose only lines were filtered out by as_of_date). A mismatch
-- here means the header-to-line aggregation multiplied or dropped an order
-- with at least one line — see docs/SCHEMA_NOTES.md Block 3.
select line_grain_order_count, fct_orders_count
from (
    select
        (select count(distinct order_id) from {{ ref('fct_order_items') }}) as line_grain_order_count,
        (select count(*) from {{ ref('fct_orders') }}) as fct_orders_count
)
where line_grain_order_count != fct_orders_count
