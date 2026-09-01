select
    id                      as product_id,
    category,
    name                    as product_name,
    brand,
    retail_price,
    department,
    sku,
    distribution_center_id
from {{ source('thelook', 'products') }}