-- Demonstrates foreign key indexes
-- movies.db

-- Time searching for movies Tom Hanks has starred in
.TIMER ON
SELECT title
FROM movies
WHERE id IN (
              SELECT movie_id
              FROM stars
              WHERE person_id = (
                                  SELECT id
                                  FROM people
                                  WHERE name = 'Tom Hanks'
                                )
            );
.TIMER OFF

-- Identify which columns we should create indexes on
EXPLAIN QUERY PLAN
SELECT title
FROM movies
WHERE id IN (
              SELECT movie_id
              FROM stars
              WHERE person_id = (
                                  SELECT id
                                  FROM people
                                  WHERE name = 'Tom Hanks'
                                )
            );

-- Create index on foreign key
.TIMER ON
CREATE INDEX person_index ON stars (person_id);

-- Create index to speed name look-ups
CREATE INDEX name_index ON people (name);
.TIMER OFF

EXPLAIN QUERY PLAN
SELECT title
FROM movies
WHERE id IN (
              SELECT movie_id
              FROM stars
              WHERE person_id = (
                                  SELECT id
                                  FROM people
                                  WHERE name = 'Tom Hanks'
                                )
            );

-- Make person_index a covering index for the above query
CREATE INDEX person_index ON stars (person_id, movie_id);

EXPLAIN QUERY PLAN
SELECT title
FROM movies
WHERE id IN (
              SELECT movie_id
              FROM stars
              WHERE person_id = (
                                  SELECT id
                                  FROM people
                                  WHERE name = 'Tom Hanks'
                                )
            );

-- Compare runtime with indexes
.TIMER ON
SELECT title
FROM movies
WHERE id IN (
              SELECT movie_id
              FROM stars
              WHERE person_id IN (
                                   SELECT id
                                   FROM people
                                   WHERE name = 'Tom Hanks'
                                 )
            );
.TIMER OFF
