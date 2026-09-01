select
    p.product_id,
    p.product_name,
    p.category,
    p.brand,
    p.department,
    p.retail_price,
    p.sku,
    dc.name as distribution_center
from {{ ref('stg_products') }} p
left join {{ ref('stg_distribution_centers') }} dc
    on dc.id = p.distribution_center_id