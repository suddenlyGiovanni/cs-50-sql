-- Hits are great, but so are RBIs!
--
-- In 12.sql, write a SQL query to find the players among the 10 least expensive players per hit and among the 10 least expensive players per RBI in 2001.
--
-- Your query should return a table with two columns, one for the players’ first names and one of their last names.
-- You can calculate a player’s salary per RBI by dividing their 2001 salary by their number of RBIs in 2001.
-- You may assume, for simplicity, that a player will only have one salary and one performance in 2001.
-- Order your results by player ID, least to greatest (or alphabetically by last name, as both are the same in this case!).
-- Keep in mind the lessons you’ve learned in 10.sql and 11.sql!


-- First, define a CTE for the common part of the query:
WITH PlayerStats AS (SELECT pf.player_id,
                            s.salary,
                            pf.H,
                            pf.RBI
                     FROM main.performances pf
                            INNER JOIN main.salaries s
                                       ON pf.player_id = s.player_id
                                         AND pf.year = s.year
                     WHERE pf.year = 2001),

-- Subquery for the top 10 least expensive players per hit:
     TopHitPlayers AS (SELECT player_id,
                              (salary / H) AS dollars_per_hit
                       FROM PlayerStats
                       WHERE H > 0
                       ORDER BY dollars_per_hit ASC
                       LIMIT 10),

-- Subquery for the top 10 least expensive players per RBI:
     TopRBIPlayers AS (SELECT player_id,
                              (salary / RBI) AS dollars_per_rbi
                       FROM PlayerStats
                       WHERE RBI > 0
                       ORDER BY dollars_per_rbi ASC
                       LIMIT 10)

-- Main query to find players in both subqueries:
SELECT p.first_name,
       p.last_name
--        dollars_per_hit,
--        dollars_per_rbi
FROM TopHitPlayers th
       INNER JOIN
                  TopRBIPlayers tr ON th.player_id = tr.player_id
       INNER JOIN main.players p ON th.player_id = p.id
ORDER BY p.id ASC,
         p.last_name ASC;
