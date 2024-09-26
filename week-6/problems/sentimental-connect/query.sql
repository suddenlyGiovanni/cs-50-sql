-- Define a common table expression to find Alan's ID
  WITH alan_id AS (
                  SELECT u.id
                    FROM users u
                   WHERE u.username = 'alan'
                  )
-- Select all the connections of the user "Alan" and display their info
SELECT DISTINCT
       u2.id
     , u2.username
     , u2.first_name
     , u2.last_name
     , u2.password
  FROM friendship
    JOIN users   u1 ON friendship.user_a_id = u1.id OR friendship.user_b_id = u1.id
    JOIN users   u2
    ON (u2.id = friendship.user_a_id AND u2.id != u1.id) OR (u2.id = friendship.user_b_id AND u2.id != u1.id)
    JOIN alan_id a ON a.id = u1.id;



SELECT users.username
     , concat_ws(' ', users.first_name, users.last_name) AS name
     , institutions.name                                 AS school
     , institutions.type
     , degree.name                                       AS degree
     , education.start_date
     , education.end_date
  FROM education
    JOIN degree ON degree.id = education.degree_type
    JOIN users ON users.id = education.user_id
    JOIN institutions ON institutions.id = education.institution_id;


-- query all users that have an affiliation with Harvard
SELECT user_id
     , concat_ws(' ', users.first_name, users.last_name) AS name
     , degree.name
     , start_date
     , end_date
  FROM education
    JOIN degree ON degree.id = education.degree_type
    JOIN institutions ON institutions.id = education.institution_id
    JOIN users ON education.user_id = users.id
 WHERE education.institution_id = (
                                  SELECT id
                                    FROM institutions
                                   WHERE name = 'Harvard University'
                                  )
