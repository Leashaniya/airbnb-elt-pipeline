-- Host dimension: who owns the listings.
select
    host_id,
    host_name,
    host_since,
    host_location,
    host_response_time,
    host_response_rate,
    is_superhost,
    is_identity_verified,
    host_listings_count
from {{ ref('stg_hosts') }}
