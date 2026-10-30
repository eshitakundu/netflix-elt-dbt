-- External IDs for each movie. Some movies have no TMDb id, so that cast is lenient.
with source as (
    select * from {{ source('raw', 'links') }}
)

select
    cast(movieId as integer) as movie_id,
    'tt' || imdbId as imdb_id,
    try_cast(nullif(tmdbId, '') as integer) as tmdb_id
from source
