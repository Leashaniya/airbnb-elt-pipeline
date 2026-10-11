-- Listing dimension: what is being rented, enriched with review and availability stats.
select
    l.listing_id,
    l.host_id,
    l.listing_name,
    l.neighbourhood,
    l.neighbourhood_group,
    l.property_type,
    l.room_type,
    l.accommodates,
    l.bedrooms,
    l.bathrooms,
    l.beds,
    l.price_per_night,
    l.cleaning_fee,
    l.minimum_nights,
    l.is_instant_bookable,
    l.cancellation_policy,
    l.review_score_rating,
    coalesce(r.total_reviews, 0)   as total_reviews,
    r.first_review_date,
    r.last_review_date,
    a.occupancy_rate,
    a.avg_available_price,
    l.latitude,
    l.longitude
from {{ ref('stg_listings') }} l
left join {{ ref('int_listing_review_stats') }} r on l.listing_id = r.listing_id
left join {{ ref('int_listing_availability_stats') }} a on l.listing_id = a.listing_id
