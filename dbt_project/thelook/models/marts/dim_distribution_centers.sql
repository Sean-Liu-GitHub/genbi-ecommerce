select
    id                as distribution_center_id,
    name
from {{ ref('stg_distribution_centers') }}