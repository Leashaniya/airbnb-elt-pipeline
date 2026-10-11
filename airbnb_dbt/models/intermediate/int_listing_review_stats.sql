-- Review activity per listing.
select
    listing_id,
    count(*)            as total_reviews,
    min(review_date)    as first_review_date,
    max(review_date)    as last_review_date
from {{ ref('stg_reviews') }}
group by listing_id
