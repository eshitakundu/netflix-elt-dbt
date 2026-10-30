-- One row per (user, movie) rating. Ratings are on a 0.5 to 5.0 scale in half stars;
-- the timestamp arrives as Unix seconds.
with source as (
    select * from {{ source('raw', 'ratings') }}
)

select
    cast(userId as integer) || '-' || cast(movieId as integer) as rating_id,
    cast(userId as integer) as user_id,
    cast(movieId as integer) as movie_id,
    cast(rating as decimal(2, 1)) as rating,
    to_timestamp(cast("timestamp" as bigint)) as rated_at
from source
