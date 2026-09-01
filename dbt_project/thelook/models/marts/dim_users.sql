-- marts/dim_users.sql
select
    user_id,
    first_name,
    last_name,
    age,
    gender,
    state,
    postal_code,
    city,
    country,
    traffic_source,
    signed_up_at
from {{ ref('stg_users') }}