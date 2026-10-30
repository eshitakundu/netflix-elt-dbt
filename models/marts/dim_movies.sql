-- One row per movie with its rating profile.
-- weighted_rating is an IMDb-style Bayesian average: movies with few ratings are
-- pulled toward the global mean, so a single 5-star vote can't top the chart.
{% set min_votes = var('min_votes_for_weighting', 10) %}

with ratings as (
    select
        movie_id,
        count(*) as rating_count,
        avg(rating) as avg_rating,
        min(rated_at) as first_rated_at,
        max(rated_at) as last_rated_at
    from {{ ref('fct_ratings') }}
    group by movie_id
),

global_mean as (
    select avg(rating) as mean_rating from {{ ref('fct_ratings') }}
)

select
    movies.movie_id,
    movies.title,
    movies.release_year,
    {{ decade_of('movies.release_year') }} as release_decade,
    movies.genres,
    movies.genres[1] as primary_genre,
    links.imdb_id,
    links.tmdb_id,
    coalesce(ratings.rating_count, 0) as rating_count,
    round(ratings.avg_rating, 2) as avg_rating,
    round(
        (ratings.rating_count / (ratings.rating_count + {{ min_votes }})) * ratings.avg_rating
        + ({{ min_votes }} / (ratings.rating_count + {{ min_votes }})) * global_mean.mean_rating,
        3
    ) as weighted_rating,
    ratings.first_rated_at,
    ratings.last_rated_at
from {{ ref('stg_movies') }} as movies
left join {{ ref('stg_links') }} as links using (movie_id)
left join ratings using (movie_id)
cross join global_mean
