-- One row per listing per day. Price is only filled in when the night is available.
with source as (
    select * from {{ source('raw', 'calendar') }}
)

select
    try_to_number(listing_id)          as listing_id,
    try_to_date(date)                  as calendar_date,
    {{ to_bool('available') }}         as is_available,
    {{ clean_money('price') }}         as price
from source
where try_to_number(listing_id) is not null
