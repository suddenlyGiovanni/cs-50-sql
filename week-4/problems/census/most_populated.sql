-- In most_populated.sql, write a SQL statement to create a view named most_populated.
-- This view should contain, in order from greatest to least, the most populated districts in Nepal.

DROP VIEW IF EXISTS most_populated;
CREATE VIEW most_populated AS
SELECT c.district,                      -- which is the name of the district
       SUM(c.families)   AS families,   -- which is the total number of families in the district.
       SUM(c.households) AS households, -- which is the total number of households in the district
       SUM(c.population) AS population, -- which is the total population of the district
       SUM(c.male)       AS male,       -- which is the total number of people identifying as male in the district
       SUM(c.female)     AS female      -- which is the total number of people identifying as female in the district.
FROM census c
GROUP BY c.district
ORDER BY population DESC;
