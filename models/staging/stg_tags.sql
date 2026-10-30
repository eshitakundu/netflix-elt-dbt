-- Free-text tags users attach to movies. Normalised to lower case so
-- "Pixar" and "pixar" count as the same tag.
with source as (
    select * from {{ source('raw', 'tags') }}
)

select
    cast(userId as integer) as user_id,
    cast(movieId as integer) as movie_id,
    lower(trim(tag)) as tag,
    to_timestamp(cast("timestamp" as bigint)) as tagged_at
from source
where nullif(trim(tag), '') is not null
