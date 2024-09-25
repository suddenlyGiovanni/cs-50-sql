-- In total.sql, write a SQL statement to create a view named total.
-- This view should contain the sums for each numeric column in census, across all districts and localities.
DROP VIEW IF EXISTS total;
CREATE VIEW total AS
SELECT SUM(c.families)   AS families,   -- which is the sum of families from every locality in Nepal
       SUM(c.households) AS households, -- which is the sum of households from every locality in Nepal
       SUM(c.population) AS population, -- which is the sum of the population from every locality in Nepal
       SUM(c.male)       AS male,       -- which is the sum of people identifying as male from every locality in Nepal
       SUM(c.female)     AS female      -- which is the sum of people identifying as female from every locality in Nepal
FROM census c;
