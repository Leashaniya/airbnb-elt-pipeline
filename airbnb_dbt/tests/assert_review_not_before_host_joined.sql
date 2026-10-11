-- A review should not be dated before the host joined Airbnb.
-- The source data has a small number of these, so this test warns instead of failing
-- the build: the rows are kept, but the issue is reported on every run.
{{ config(severity='warn') }}

select
    r.review_id,
    r.review_date,
    h.host_since
from {{ ref('fct_reviews') }} r
join {{ ref('dim_hosts') }} h on r.host_id = h.host_id
where r.review_date < h.host_since
