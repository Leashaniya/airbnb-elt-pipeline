-- One row per listing: renamed columns, correct types, prices as numbers.
with source as (
    select * from {{ source('raw', 'listings') }}
)

select
    try_to_number(id)                          as listing_id,
    try_to_number(host_id)                     as host_id,
    trim(name)                                 as listing_name,
    neighbourhood_cleansed                     as neighbourhood,
    neighbourhood_group_cleansed               as neighbourhood_group,
    property_type,
    room_type,
    try_to_number(accommodates)                as accommodates,
    try_to_decimal(bathrooms, 4, 1)            as bathrooms,
    try_to_number(bedrooms)                    as bedrooms,
    try_to_number(beds)                        as beds,
    {{ clean_money('price') }}                 as price_per_night,
    {{ clean_money('cleaning_fee') }}          as cleaning_fee,
    try_to_number(minimum_nights)              as minimum_nights,
    try_to_number(maximum_nights)              as maximum_nights,
    {{ to_bool('instant_bookable') }}          as is_instant_bookable,
    cancellation_policy,
    try_to_number(number_of_reviews)           as number_of_reviews,
    try_to_number(review_scores_rating)        as review_score_rating,
    try_to_decimal(latitude, 9, 6)             as latitude,
    try_to_decimal(longitude, 9, 6)            as longitude,
    try_to_date(last_scraped)                  as scraped_date,
    _loaded_at
from source
where try_to_number(id) is not null
