INSERT INTO users (first_name, last_name, username, password)
VALUES ('Alan', 'Garber', 'alan', 'password')
     , ('Martin', 'Scorsese', 'martin', 'password')
     , ('Quentin', 'Tarantino', 'quentin', 'password')
     , ('Reid', 'Hoffman', 'reid', 'password');



INSERT INTO institutions (name, type, location, year)
VALUES ( 'Harvard University', 'Higher Education'
       , 'Cambridge, Massachusetts, USA', 1636);



INSERT INTO degree (name)
VALUES ('BA')
     , ('MA')
     , ('PhD');



INSERT INTO education (user_id, institution_id, degree_type, start_date, end_date)
VALUES ((
        SELECT id
          FROM users
         WHERE username = 'alan'
        ), (
           SELECT id
             FROM institutions
            WHERE name = 'Harvard University'
           ), (
              SELECT id
                FROM degree
               WHERE name = 'BA'
              ), '1973-09-01', '1976-06-01')
     , ((
        SELECT id
          FROM users u
         WHERE u.username = 'reid'
        ), (
           SELECT id
             FROM institutions
            WHERE name = 'Harvard University'
           ), (
              SELECT id
                FROM degree
               WHERE name = 'MA'
              ), '1999-09-01', '2001-06-01');



INSERT INTO companies (name, industry, location)
VALUES ( 'LinkedIn'
       , 'Technology'
       , 'Sunnyvale, California, USA');



INSERT INTO friendship (user_a_id, user_b_id)
VALUES ((
        SELECT id
          FROM users
         WHERE username = 'alan'
        ), (
           SELECT id
             FROM users
            WHERE username = 'reid'
           ))
     , ((
        SELECT id
          FROM users
         WHERE username = 'alan'
        ), (
           SELECT id
             FROM users
            WHERE username = 'quentin'
           ))
     , ((
        SELECT id
          FROM users
         WHERE username = 'reid'
        ), (
           SELECT id
             FROM users
            WHERE username = 'martin'
           ));



INSERT INTO employment (user_id, company_id, title, start_date, end_date)
VALUES ( (
         SELECT id
           FROM users
          WHERE username = 'reid'
         )
       , (
         SELECT id
           FROM companies
          WHERE name = 'LinkedIn'
         )
       , 'CEO'
       , '2003-01-01'
       , '2007-02-01');
