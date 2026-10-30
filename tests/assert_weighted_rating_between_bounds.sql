-- A Bayesian average is a blend of the movie's own average and the global mean,
-- so it must stay inside the 0.5 to 5.0 rating scale. Returns offending rows.
select movie_id, weighted_rating
from {{ ref('dim_movies') }}
where weighted_rating is not null
  and (weighted_rating < 0.5 or weighted_rating > 5.0)
