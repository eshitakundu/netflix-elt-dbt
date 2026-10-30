-- One row per user, segmented by how much they rate.
with activity as (
    select
        user_id,
        count(*) as ratings_count,
        round(avg(rating), 2) as avg_rating_given,
        min(rated_at) as first_active_at,
        max(rated_at) as last_active_at
    from {{ ref('fct_ratings') }}
    group by user_id
)

select
    user_id,
    ratings_count,
    avg_rating_given,
    first_active_at,
    last_active_at,
    case
        when ratings_count >= 500 then 'power'
        when ratings_count >= 100 then 'regular'
        else 'casual'
    end as rater_segment
from activity
