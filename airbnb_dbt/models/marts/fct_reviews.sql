-- Review fact: one row per review.
-- Incremental: after the first full build, each run only adds reviews newer
-- than the latest review_date already in the table.
{{ config(materialized='incremental', unique_key='review_id', on_schema_change='append_new_columns') }}

select
    r.review_id,
    r.listing_id,
    l.host_id,
    r.review_date,
    r.reviewer_id,
    length(r.comments)  as comment_length,
    r.comments,
    r._loaded_at
from {{ ref('stg_reviews') }} r
join {{ ref('stg_listings') }} l on r.listing_id = l.listing_id

{% if is_incremental() %}
where r.review_date > (select max(review_date) from {{ this }})
{% endif %}
