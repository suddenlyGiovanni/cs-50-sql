-- A parent asks you for advice on finding the best public school districts in Massachusetts.
-- In 12.sql, write a SQL query to find public school districts with above-average per-pupil expenditures and an above-average percentage of teachers rated “exemplary”.
-- Your query should return the districts’ names, along with their per-pupil expenditures and percentage of teachers rated exemplary.
-- Sort the results first by the percentage of teachers rated exemplary (high to low), then by the per-pupil expenditure (high to low).
SELECT d.name,
       e.per_pupil_expenditure,
       se.exemplary
FROM main.districts d
       JOIN main.expenditures e
            ON d.id = e.district_id
       JOIN main.staff_evaluations se
            ON d.id = se.district_id
WHERE d.type = 'Public School District'
  AND (SELECT ROUND(AVG(per_pupil_expenditure), 2) AS "average per-pupil expenditures"
       FROM main.expenditures) <= e.per_pupil_expenditure
  AND se.exemplary >= (SELECT ROUND(AVG(exemplary), 2) AS "avarage exemplary teachers"
                       FROM main.staff_evaluations)
ORDER BY se.exemplary DESC,
         e.per_pupil_expenditure DESC;
