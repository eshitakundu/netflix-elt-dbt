-- Every rating of a movie with at least one genre should be counted in the genre mart
-- once per genre. If the bridge or join drops or duplicates rows, this returns a row.
with expected as (
    select count(*) as n
    from {{ ref('fct_ratings') }} as ratings
    inner join {{ ref('bridge_movie_genres') }} as bridge using (movie_id)
),

actual as (
    select sum(rating_count) as n
    from {{ ref('mart_genre_performance') }}
)

select expected.n as expected_rows, actual.n as actual_rows
from expected
cross join actual
where expected.n != actual.n
