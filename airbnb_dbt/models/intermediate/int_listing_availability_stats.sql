-- Availability over the next year per listing.
-- Nights that are not available are treated as booked (or blocked by the host).
select
    listing_id,
    count(*)                                        as calendar_days,
    count_if(is_available)                          as available_days,
    round(1 - count_if(is_available) / count(*), 4) as occupancy_rate,
    round(avg(case when is_available then price end), 2) as avg_available_price
from {{ ref('stg_calendar') }}
group by listing_id
