DROP TABLE IF EXISTS passenger;
DROP TABLE IF EXISTS flight;
DROP TABLE IF EXISTS checkin;
DROP TABLE IF EXISTS airline;
DROP TABLE IF EXISTS concourse;
DROP TABLE IF EXISTS airline_concourse;

CREATE TABLE passenger (
  id         INTEGER PRIMARY KEY AUTOINCREMENT,  -- passenger id, automatically handled by the db.
  first_name TEXT    NOT NULL,                   -- first name, e.g. 'Amelia'
  last_name  TEXT    NOT NULL,                   -- last name, e.g. 'Earhart
  age        INTEGER NOT NULL CHECK ( age >= 0 ) -- valid age, e.g. 39
  );

CREATE TABLE airline (
  id   INTEGER PRIMARY KEY AUTOINCREMENT,
  name TEXT NOT NULL -- name of the airline; e.g. 'Delta', 'Air France' etc.
  );


CREATE TABLE concourse (
  name TEXT PRIMARY KEY UNIQUE CHECK ( name IN ('A', 'B', 'C', 'D', 'E', 'F', 'T'))
  );

CREATE TABLE airline_concourse (
  airline_id     INTEGER NOT NULL, -- relation to e.g. Delta
  concourse_name TEXT    NOT NULL, -- e.g. 'A' | 'B' | ... | 'T'
  FOREIGN KEY (concourse_name) REFERENCES concourse (name),
  FOREIGN KEY (airline_id) REFERENCES airline (id),
  PRIMARY KEY (airline_id, concourse_name)
  );


CREATE TABLE flight (
  id         INTEGER PRIMARY KEY AUTOINCREMENT,
  number     INTEGER NOT NULL CHECK ( number > 0 ),                   -- e.g. 900
  airline_id INTEGER NOT NULL,                                        -- relation airline e.g. Delta
  "from"     TEXT    NOT NULL CHECK ( "from" GLOB '[A-Z][A-Z][A-Z]'), -- e.g. LAX
  "to"       TEXT    NOT NULL CHECK ( "to" GLOB '[A-Z][A-Z][A-Z]'),   -- e.g. ATL
  departure  TEXT    NOT NULL,                                        -- utc datetime 'YYYY-MM-DD HH:MM'
  arrival    TEXT    NOT NULL,                                        -- utc datetime 'YYYY-MM-DD HH:MM'
  CONSTRAINT flight_unique UNIQUE (number, airline_id, "from", "to", departure),
  CONSTRAINT valid_departure_time_format CHECK ( departure GLOB
                                                 '[0-9][0-9][0-9][0-9]-[0-1][0-9]-[0-3][0-9] [0-2][0-9]:[0-5][0-9]' ),
  CONSTRAINT valid_arrival_time_format CHECK ( arrival GLOB
                                               '[0-9][0-9][0-9][0-9]-[0-1][0-9]-[0-3][0-9] [0-2][0-9]:[0-5][0-9]' ),
  CONSTRAINT valid_arrival_time CHECK ( UNIXEPOCH(arrival) - UNIXEPOCH(departure) > 0 ),
  FOREIGN KEY (airline_id) REFERENCES airline (id)
  );


CREATE TABLE checkin (
  id           INTEGER PRIMARY KEY AUTOINCREMENT,
  datetime     TEXT    NOT NULL DEFAULT CURRENT_TIMESTAMP,
  passenger_id INTEGER NOT NULL,
  flight_id    INTEGER NOT NULL,
  CONSTRAINT valid_datetime CHECK ( datetime GLOB
                                    '[0-9][0-9][0-9][0-9]-[0-1][0-9]-[0-3][0-9] [0-2][0-9]:[0-5][0-9]:[0-5][0-9]' ),
  FOREIGN KEY (passenger_id) REFERENCES passenger (id),
  FOREIGN KEY (flight_id) REFERENCES flight (id)
  );
