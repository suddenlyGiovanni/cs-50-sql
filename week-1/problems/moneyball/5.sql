-- It’s a bit of a slow day in the office.
-- Though Satchel no longer plays, in 5.sql, write a SQL query to find all teams that Satchel Paige played for.
--
-- Your query should return a table with a single column, one for the name of the teams.
SELECT DISTINCT t.name
FROM main.performances pf
       INNER JOIN main.teams t
                  ON pf.team_id = t.id
WHERE pf.player_id = (SELECT p.id
                      FROM main.players p
                      WHERE p.first_name = 'Satchel'
                        AND p.last_name = 'Paige')
ORDER BY pf.year ASC;
