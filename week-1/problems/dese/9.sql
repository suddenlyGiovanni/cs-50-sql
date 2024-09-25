-- Another parent wants to send their child to a district with few other students.
-- In 9.sql, write a SQL query to find the name (or names) of the school district(s) with the single least number of pupils.
-- Report only the name(s).
SELECT d.name
FROM expenditures e
       INNER JOIN districts d
                  ON e.district_id = d.id
WHERE e.pupils = (SELECT MIN(pupils)
                  FROM expenditures);
