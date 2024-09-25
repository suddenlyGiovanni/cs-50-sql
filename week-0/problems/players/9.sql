-- write a SQL query to find the players who played their final game in the MLB in 2022.
-- Sort the results alphabetically by first name, then by last name.
SELECT first_name, last_name
FROM players
WHERE final_game BETWEEN '2022-01-01' AND '2022-12-31'
ORDER BY players.first_name ASC, last_name ASC;
