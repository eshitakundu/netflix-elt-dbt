-- Rating events, the grain every rating metric is built from.
select
    rating_id,
    user_id,
    movie_id,
    rating,
    rated_at,
    cast(rated_at as date) as rated_date,
    year(rated_at) as rated_year
from {{ ref('stg_ratings') }}
