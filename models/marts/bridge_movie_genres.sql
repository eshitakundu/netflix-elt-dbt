-- One row per (movie, genre), with the reporting group from the genre_groups seed.
with movie_genres as (
    select
        movie_id,
        unnest(genres) as genre
    from {{ ref('stg_movies') }}
)

select
    movie_genres.movie_id,
    movie_genres.genre,
    genre_groups.genre_group
from movie_genres
left join {{ ref('genre_groups') }} as genre_groups
    on movie_genres.genre = genre_groups.genre
