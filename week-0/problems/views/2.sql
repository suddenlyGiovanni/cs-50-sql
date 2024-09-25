-- write a SQL query to list the average colors of prints by Hokusai that include “river” in the English title.
-- (As an aside, do they have any hint of blue?)

SELECT views.english_title,
       views.average_color
--        SUBSTRING(views.average_color, -2) AS
--          blue_component
FROM views
WHERE artist = 'Hokusai'
  AND english_title LIKE '%river%'
