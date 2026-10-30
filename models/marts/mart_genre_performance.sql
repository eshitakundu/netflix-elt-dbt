-- How each genre performs: catalogue size, audience volume and rating quality.
-- A movie with several genres counts once in each of them.
with genre_ratings as (
    select
        bridge.genre,
        bridge.genre_group,
        ratings.movie_id,
        ratings.rating
    from {{ ref('bridge_movie_genres') }} as bridge
    inner join {{ ref('fct_ratings') }} as ratings using (movie_id)
),

catalogue as (
    select genre, count(*) as movie_count
    from {{ ref('bridge_movie_genres') }}
    group by genre
)

select
    genre_ratings.genre,
    any_value(genre_ratings.genre_group) as genre_group,
    catalogue.movie_count,
    count(*) as rating_count,
    round(count(*) / catalogue.movie_count, 1) as ratings_per_movie,
    round(avg(genre_ratings.rating), 2) as avg_rating,
    round(avg(case when genre_ratings.rating >= 4 then 1.0 else 0.0 end), 3) as share_rated_4_plus
from genre_ratings
inner join catalogue using (genre)
group by genre_ratings.genre, catalogue.movie_count
