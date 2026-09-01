select
    id                as user_id,
    first_name,
    last_name,
    age,
    gender,
    state,
    postal_code,
    city,
    country,
    traffic_source,
    created_at        as signed_up_at
from {{ source('thelook', 'users') }}