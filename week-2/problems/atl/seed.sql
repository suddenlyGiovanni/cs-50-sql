INSERT INTO concourse
  ( name )
VALUES
  ( 'A' ),
  ( 'B' ),
  ( 'C' ),
  ( 'D' ),
  ( 'E' ),
  ( 'F' ),
  ( 'T' );


INSERT INTO airline
  ( name )
VALUES
  ( 'Delta'            ),
  ( 'Air France'       ),
  ( 'Korean Air'       ),
  ( 'Turkish Airlines' ),
  ( 'British Airways'  );



INSERT
INTO airline_concourse
  ( airline_id, concourse_name )
VALUES
  ( 1, 'A' ),
  ( 1, 'B' ),
  ( 1, 'C' ),
  ( 1, 'D' ),
  ( 1, 'E' ),
  ( 1, 'F' ),
  ( 1, 'T' );


INSERT INTO passenger
  ( first_name, last_name, age )
VALUES
  ( 'Amelia', 'Earhart', '39' );


INSERT INTO flight
  ( number, airline_id, "from", "to", departure, arrival )
VALUES
  ( 300, (
           SELECT id
           FROM airline
           WHERE name = 'Delta'
         ), 'ATL', 'BOS', '2023-08-03 18:46', '2023-08-03 21:09' );


INSERT INTO checkin
  ( passenger_id, flight_id )
VALUES
  ( (
      SELECT id FROM passenger p WHERE p.last_name = 'Earhart' AND p.first_name = 'Amelia'
    ), (
         SELECT id FROM flight f WHERE f.number = 300 AND f.departure = '2023-08-03 18:46'
       ) );
