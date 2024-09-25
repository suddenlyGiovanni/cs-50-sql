-- list the titles of episodes from season 6 (2008) that were released early, in 2007.

SELECT title
FROM episodes
WHERE season = 6
  AND DATE(air_date) BETWEEN DATE('2007-01-01') AND DATE('2007-12-31');
