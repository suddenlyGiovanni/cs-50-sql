-- Your general manager (i.e., the person who makes decisions about player contracts) asks you whether the team should trade a current player for Cal Ripken Jr., a star player who’s likely nearing his retirement.
-- In 2.sql, write a SQL query to find Cal Ripken Jr.’s salary history.
--
-- Sort by year in descending order.
-- Your query should return a table with two columns, one for year and one for salary.


SELECT s.year, s.salary
FROM main.salaries s
WHERE player_id = (SELECT p.id
                   FROM main.players p
                   WHERE p.last_name = 'Ripken'
                     AND p.first_name = 'Cal')
ORDER BY s.year DESC;
