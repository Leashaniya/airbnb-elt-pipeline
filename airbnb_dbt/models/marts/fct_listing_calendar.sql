-- Daily availability fact: one row per listing per day, with the asking price.
select
    c.listing_id,
    l.host_id,
    c.calendar_date,
    c.is_available,
    c.price
from {{ ref('stg_calendar') }} c
join {{ ref('stg_listings') }} l on c.listing_id = l.listing_id
