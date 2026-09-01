select
    id,
    name
from {{ source('thelook', 'distribution_centers') }}