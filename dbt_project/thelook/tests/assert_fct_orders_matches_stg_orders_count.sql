-- Fan-out canary: fct_orders must have exactly one row per stg_orders row.
-- A mismatch here means the header-to-line aggregation multiplied or
-- dropped an order — see docs/SCHEMA_NOTES.md Block 3.
select stg_orders_count, fct_orders_count
from (
    select
        (select count(*) from {{ ref('stg_orders') }}) as stg_orders_count,
        (select count(*) from {{ ref('fct_orders') }}) as fct_orders_count
)
where stg_orders_count != fct_orders_count
