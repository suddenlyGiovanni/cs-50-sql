INSERT INTO user
  ( first_name, last_name, username, password )
VALUES
  ( 'Alan',    'Garber',    'alan',    'password' ),
  ( 'Martin',  'Scorsese',  'martin',  'password' ),
  ( 'Quentin', 'Tarantino', 'quentin', 'password' ),
  ( 'Reid',    'Hoffman',   'reid',    'password' );

INSERT INTO education_institution_type
  ( type )
VALUES
  ( 'Elementary School' ),
  ( 'Middle School'     ),
  ( 'High School'       ),
  ( 'Lower School'      ),
  ( 'Upper School'      ),
  ( 'College'           ),
  ( 'University'        );


INSERT INTO education_institution
  ( name, type, location, year )
VALUES
  ( 'Harvard', (
                 SELECT id
                 FROM education_institution_type t
                 WHERE t.type = 'University'
               ), 'Cambridge, Massachusetts, USA', 1636 );



INSERT INTO degree_type
  ( name )
VALUES
  ( 'BA'  ),
  ( 'MA'  ),
  ( 'PhD' );



INSERT INTO education_affiliation
  ( user_id, education_institution_id, degree_type, start_date, end_date )
VALUES
  ( (
      SELECT id
      FROM user u
      WHERE u.username = 'alan'
    ), (
         SELECT id
         FROM education_institution e
         WHERE e.name = 'Harvard'
       ), (
            SELECT id
            FROM degree_type t
            WHERE t.name = 'BA'
          ), '1973-09-01', '1976-06-01' ),
  ( (
      SELECT id
      FROM user u
      WHERE u.username = 'reid'
    ), (
         SELECT id
         FROM education_institution e
         WHERE e.name = 'Harvard'
       ), (
            SELECT id
            FROM degree_type t
            WHERE t.name = 'MA'
          ), '1999-09-01', '2001-06-01' );


INSERT INTO industry
  ( name )
VALUES
  ( 'technology' ),
  ( 'education'  ),
  ( 'finance'    );


INSERT INTO company
  ( name, industry, location )
VALUES
  ( 'LinkedIn', (
                  SELECT id
                  FROM industry i
                  WHERE i.name = 'technology'
                ), ' Sunnyvale, California, USA' );



INSERT INTO user_connection
  ( user_a_id, user_b_id )
VALUES
  ( (
      SELECT id
      FROM user u
      WHERE u.username = 'alan'
    ), (
         SELECT id
         FROM user u
         WHERE u.username = 'reid'
       ) ),
  ( (
      SELECT id
      FROM user u
      WHERE u.username = 'alan'
    ), (
         SELECT id
         FROM user u
         WHERE u.username = 'quentin'
       ) ),
  ( (
      SELECT id
      FROM user u
      WHERE u.username = 'reid'
    ), (
         SELECT id
         FROM user u
         WHERE u.username = 'martin'
       ) );



INSERT INTO company_affiliation
  ( user_id, company_id, title, start_date, end_date )
VALUES
  ( (
      SELECT u.id
      FROM user u
      WHERE u.username = 'reid'
    ), (
         SELECT c.id
         FROM company c
         WHERE c.name = 'LinkedIn'
       ), 'CEO', '2003-01-01', '2007-02-01' );
