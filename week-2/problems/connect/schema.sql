DROP TABLE IF EXISTS user;
CREATE TABLE user (
  id         INTEGER PRIMARY KEY AUTOINCREMENT,
  first_name TEXT NOT NULL,
  last_name  TEXT NOT NULL,
  username   TEXT NOT NULL UNIQUE,
  password   TEXT NOT NULL
  );


-- Connections with People
-- LinkedIn’s database should be able to represent mutual (reciprocal, two-way) connections between users.
-- No need to worry about one-way connections, such as user A “following” user B without user B “following” user A.
DROP TABLE IF EXISTS user_connection;
CREATE TABLE user_connection (
  id        INTEGER PRIMARY KEY AUTOINCREMENT,
  user_a_id INTEGER NOT NULL,
  user_b_id INTEGER NOT NULL,
  FOREIGN KEY (user_a_id) REFERENCES user (id),
  FOREIGN KEY (user_b_id) REFERENCES user (id)
  );


DROP TABLE IF EXISTS education_institution;
CREATE TABLE education_institution (
  id       INTEGER PRIMARY KEY AUTOINCREMENT,
  name     TEXT    NOT NULL, -- The name of the school
  type     INTEGER NOT NULL, -- The type of school: one to one
  location TEXT    NOT NULL, -- The school’s location
  year     INTEGER NOT NULL, -- The year in which the school was founded
  FOREIGN KEY (type) REFERENCES education_institution_type (id)
  );

DROP TABLE IF EXISTS education_institution_type;
CREATE TABLE education_institution_type (
  id   INTEGER PRIMARY KEY AUTOINCREMENT,
  type TEXT UNIQUE -- The type of school (e.g., "Elementary School" "Middle School", "High School", "Lower School", "Upper School", "College", "University", etc.)
  );


DROP TABLE IF EXISTS degree_type;
CREATE TABLE degree_type (
  id   INTEGER PRIMARY KEY AUTOINCREMENT,
  name TEXT UNIQUE -- The type of degree (e.g., "BA", "MA", "PhD", etc.)
  );

-- Connections with Schools
-- A user should be able to create an affiliation with a given school.
-- And similarly, that school should be able to find its alumni.
-- Additionally, allow a user to define:
--
-- The start date of their affiliation (i.e., when they started to attend the school)
-- The end date of their affiliation (i.e., when they graduated), if applicable
-- The type of degree earned/pursued (e.g., “BA”, “MA”, “PhD”, etc.)
DROP TABLE IF EXISTS education_affiliation;
CREATE TABLE education_affiliation (
  id                       INTEGER PRIMARY KEY AUTOINCREMENT,
  start_date               TEXT    NOT NULL, -- a valid UTC date 'YYYY-MM-DD'
  end_date                 TEXT,             -- an optional valid UTC date 'YYYY-MM-DD'
  degree_type              INTEGER NOT NULL, -- The type of degree earned/pursued (e.g., “BA”, “MA”, “PhD”, etc.)
  user_id                  INTEGER NOT NULL,
  education_institution_id INTEGER NOT NULL,
  FOREIGN KEY (degree_type) REFERENCES degree_type (id),
  FOREIGN KEY (user_id) REFERENCES user (id),
  FOREIGN KEY (education_institution_id) REFERENCES user (id),
  CONSTRAINT valid_start_date_format CHECK ( start_date GLOB '[0-9][0-9][0-9][0-9]-[0-1][0-9]-[0-3][0-9]' ),
  CONSTRAINT valid_end_date_format CHECK ( end_date IS NULL OR
                                           end_date GLOB '[0-9][0-9][0-9][0-9]-[0-1][0-9]-[0-3][0-9]' ),
  CONSTRAINT valid_dates CHECK ( end_date IS NULL OR UNIXEPOCH(end_date) - UNIXEPOCH(start_date) >= 0 )
  );



DROP TABLE IF EXISTS company;
CREATE TABLE company (
  id       INTEGER PRIMARY KEY AUTOINCREMENT,
  name     TEXT    NOT NULL, -- the name of the company
  industry INTEGER NOT NULL, -- the company's industry: one to one
  location TEXT    NOT NULL, -- the company's location
  FOREIGN KEY (industry) REFERENCES industry (id)

  );


DROP TABLE IF EXISTS industry;
CREATE TABLE industry (
  id   INTEGER PRIMARY KEY AUTOINCREMENT,
  name TEXT UNIQUE -- industry (e.g. "education" | "technology" | "finance")
  );

-- Connections with Companies
-- A user should be able to create an affiliation with a given company.
-- And similarly, a company should be able to find its current and past employees.
-- Additionally, allow a user to define:
--
-- The start date of their affiliation (i.e., the date they began work with the company)
-- The end date of their affiliation (i.e., when left the company), if applicable
-- The title they held while affiliated with the company
DROP TABLE IF EXISTS company_affiliation;
CREATE TABLE company_affiliation (
  id         INTEGER PRIMARY KEY AUTOINCREMENT,
  start_date TEXT    NOT NULL, -- The start date of their affiliation (i.e., the date they began work with the company)
  --                              a valid UTC date 'YYYY-MM-DD'
  end_date   TEXT,             -- The end date of their affiliation (i.e., when left the company), if applicable,
  --                              an optional valid UTC date 'YYYY-MM-DD'
  title      TEXT    NOT NULL, -- The title they held while affiliated with the company
  user_id    INTEGER NOT NULL,
  company_id INTEGER NOT NULL,
  FOREIGN KEY (user_id) REFERENCES user (id),
  FOREIGN KEY (company_id) REFERENCES company (id),
  CONSTRAINT valid_start_date_format CHECK ( start_date GLOB '[0-9][0-9][0-9][0-9]-[0-1][0-9]-[0-3][0-9]' ),
  CONSTRAINT valid_end_date_format CHECK ( end_date IS NULL OR
                                           end_date GLOB '[0-9][0-9][0-9][0-9]-[0-1][0-9]-[0-3][0-9]' ),
  CONSTRAINT valid_dates CHECK ( end_date IS NULL OR UNIXEPOCH(end_date) - UNIXEPOCH(start_date) >= 0 )
  );
