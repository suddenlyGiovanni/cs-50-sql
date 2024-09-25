-- QUERY REQUIREMENTS
-- In 13.sql, write a SQL query to answer a question you have about the data!
-- The query should:
-- * Involve at least one JOIN or subquery
WITH
-- Calculate average per-pupil expenditure
average_expenditure AS (SELECT AVG(e.per_pupil_expenditure) AS avg_expenditure
                        FROM expenditures e),

-- Calculate average proficient rating
average_proficient_rating AS (SELECT AVG(se.proficient) AS avg_proficient
                              FROM staff_evaluations se)

-- Main query
SELECT d.name,
       e.per_pupil_expenditure,
       se.proficient
FROM districts d
       JOIN
     expenditures e ON d.id = e.district_id
       JOIN
     staff_evaluations se ON d.id = se.district_id,
     average_expenditure ae,
     average_proficient_rating apr
WHERE e.per_pupil_expenditure > ae.avg_expenditure
  AND se.proficient > apr.avg_proficient
ORDER BY se.proficient DESC,
         e.per_pupil_expenditure DESC;
