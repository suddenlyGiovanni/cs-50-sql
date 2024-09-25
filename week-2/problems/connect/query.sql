-- Define a common table expression to find Alan's ID
WITH alan_id AS (
                  SELECT u.id
                  FROM main.user u
                  WHERE u.username = 'alan'
                )

-- Select all the connections of the user "Alan" and display their info
SELECT DISTINCT u2.id, u2.username, u2.first_name, u2.last_name, u2.password
FROM main.user_connection uc
       JOIN main.user     u1 ON uc.user_a_id = u1.id OR uc.user_b_id = u1.id
       JOIN main.user     u2 ON (u2.id = uc.user_a_id AND u2.id != u1.id) OR (u2.id = uc.user_b_id AND u2.id != u1.id)
       JOIN alan_id       a ON a.id = u1.id;



SELECT u.username,
       concat_ws(' ', u.first_name, u.last_name) AS name,
       i.name                                    AS school,
       t.type,
       dt.name                                   AS degree,
       a.start_date,
       a.end_date
FROM education_affiliation             a
       JOIN main.degree_type           dt ON a.degree_type = dt.id
       JOIN user                       u ON a.user_id = u.id
       JOIN education_institution      i ON i.id = a.education_institution_id
       JOIN education_institution_type t ON t.id = i.type;


-- query all users that have an affiliation with Harvard
SELECT user_id, concat_ws(' ', u.first_name, u.last_name) AS name, dt.name, start_date, end_date
FROM education_affiliation        af
       JOIN main.degree_type      dt ON dt.id = af.degree_type
       JOIN education_institution i ON i.id = af.education_institution_id
       JOIN user                  u ON af.user_id = u.id
WHERE af.education_institution_id = (
                                      SELECT id
                                      FROM education_institution i
                                      WHERE i.name = 'Harvard'
                                    )
