-- In by_district.sql, write a SQL statement to create a view named by_district.
-- This view should contain the sums for each numeric column in census, grouped by district.

DROP VIEW IF EXISTS by_district;
CREATE VIEW by_district AS
SELECT c.district,                      -- which is the name of the district
       SUM(c.families)   AS families,   -- which is the total number of families in the district
       SUM(c.households) AS households, -- which is the total number of households in the district
       SUM(c.population) AS population, -- which is the total population of the district
       SUM(c.male)       AS male,       -- which is the total number of people identifying as male in the district.
       SUM(c.female)     AS female      -- which is the total number of people identifying as female in the district.
FROM census c
GROUP BY c.district;
