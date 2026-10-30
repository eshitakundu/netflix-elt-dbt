-- One row per movie. Splits the release year out of the title ("Heat (1995)")
-- and turns the pipe-separated genre string into a list.
with source as (
    select * from {{ source('raw', 'movies') }}
)

select
    cast(movieId as integer) as movie_id,
    trim(regexp_replace(title, '\s*\(\d{4}\)\s*$', '')) as title,
    try_cast(nullif(regexp_extract(title, '\((\d{4})\)\s*$', 1), '') as integer) as release_year,
    case
        when genres = '(no genres listed)' then []::varchar[]
        else string_split(genres, '|')
    end as genres
from source
