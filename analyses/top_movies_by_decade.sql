-- Top 5 movies per release decade by weighted rating, ignoring movies with under 50 ratings.
-- Compile with `dbt compile` and run the SQL in target/compiled against data/netflix.duckdb.
select release_decade, title, release_year, rating_count, weighted_rating
from {{ ref('dim_movies') }}
where rating_count >= 50
qualify row_number() over (partition by release_decade order by weighted_rating desc) <= 5
order by release_decade, weighted_rating desc
