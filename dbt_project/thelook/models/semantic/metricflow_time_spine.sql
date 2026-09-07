with days as (
    {{ dbt_utils.date_spine(
        'day',
        "DATE('2015-01-01')",
        "DATE('2030-01-01')"
    ) }}
)

select cast(date_day as date) as date_day
from days
