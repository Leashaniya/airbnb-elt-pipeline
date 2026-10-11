-- One row per host. Host details are repeated on every listing a host owns,
-- so keep a single row per host_id (the most recently scraped one).
with source as (
    select * from {{ source('raw', 'listings') }}
)

select
    try_to_number(host_id)                                   as host_id,
    trim(host_name)                                          as host_name,
    try_to_date(host_since)                                  as host_since,
    host_location,
    host_response_time,
    try_to_number(replace(host_response_rate, '%', '')) / 100   as host_response_rate,
    {{ to_bool('host_is_superhost') }}                       as is_superhost,
    {{ to_bool('host_identity_verified') }}                  as is_identity_verified,
    try_to_number(host_listings_count)                       as host_listings_count
from source
where try_to_number(host_id) is not null
qualify row_number() over (partition by host_id order by try_to_date(last_scraped) desc) = 1
