-- One row per review.
with source as (
    select * from {{ source('raw', 'reviews') }}
)

select
    try_to_number(id)              as review_id,
    try_to_number(listing_id)      as listing_id,
    try_to_date(date)              as review_date,
    try_to_number(reviewer_id)     as reviewer_id,
    trim(reviewer_name)            as reviewer_name,
    nullif(trim(comments), '')     as comments,
    _loaded_at
from source
where try_to_number(id) is not null
