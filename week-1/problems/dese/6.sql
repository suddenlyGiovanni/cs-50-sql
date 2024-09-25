-- DESE wants to assess which schools achieved a 100% graduation rate.
-- In 6.sql, write a SQL query to find the names of schools (public or charter!) that reported a 100% graduation rate.
SELECT s.name
FROM graduation_rates g
       INNER JOIN schools s ON g.school_id = s.id
WHERE graduated = 100;
