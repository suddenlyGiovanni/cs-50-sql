DROP TABLE IF EXISTS employment;
DROP TABLE IF EXISTS education;
DROP TABLE IF EXISTS friendship;
DROP TABLE IF EXISTS users;
DROP TABLE IF EXISTS institutions;
DROP TABLE IF EXISTS degree;
DROP TABLE IF EXISTS companies;



CREATE TABLE IF NOT EXISTS users (
  id         INT UNSIGNED PRIMARY KEY AUTO_INCREMENT,
  first_name VARCHAR(50)  NOT NULL COMMENT 'the user first name',
  last_name  VARCHAR(50)  NOT NULL COMMENT 'the user last name',
  username   VARCHAR(50)  NOT NULL UNIQUE COMMENT 'an unique username',
  password   VARCHAR(128) NOT NULL COMMENT 'a hashed password up to 128 char'
);
CREATE INDEX idx_users_username ON users(username) COMMENT 'enable the quick retrieval of users by their unique username';



CREATE TABLE IF NOT EXISTS institutions (
  id       INT UNSIGNED PRIMARY KEY AUTO_INCREMENT,
  name     VARCHAR(50)                                       NOT NULL UNIQUE COMMENT 'The name of the school',
  type     ENUM ('Primary', 'Secondary', 'Higher Education') NOT NULL COMMENT 'The type of school',
  location VARCHAR(255)                                      NOT NULL COMMENT 'The school’s location',
  year     SMALLINT UNSIGNED                                 NOT NULL COMMENT 'The year in which the school was founded'
);


CREATE INDEX idx_institutions_name ON institutions(name) COMMENT 'enable the quick retrieval of an institution by their unique name';



CREATE TABLE IF NOT EXISTS degree (
  id   INT UNSIGNED PRIMARY KEY AUTO_INCREMENT,
  name VARCHAR(50) UNIQUE NOT NULL COMMENT 'The type of degree (e.g., "BA", "MA", "PhD", etc.)'
);


CREATE INDEX idx_degree_type ON degree(name) COMMENT 'enable the quick retrieval of an degree by their unique name';



CREATE TABLE IF NOT EXISTS companies (
  id       INT UNSIGNED PRIMARY KEY AUTO_INCREMENT,
  name     VARCHAR(255) UNIQUE                          NOT NULL COMMENT 'the name of the company',
  industry ENUM ('Technology', 'Education', 'Business') NOT NULL COMMENT 'the company industry: one to one',
  location VARCHAR(255)                                 NOT NULL COMMENT 'the company location'
);


CREATE INDEX idx_companies_name ON companies(name) COMMENT 'enable the quick retrieval of an company by their unique name';


-- Connections with People
-- LinkedIn’s database should be able to represent mutual (reciprocal, two-way) connections between users.
-- No need to worry about one-way connections, such as user A “following” user B without user B “following” user A.
CREATE TABLE IF NOT EXISTS friendship (
  id        INT UNSIGNED PRIMARY KEY AUTO_INCREMENT,
  user_a_id INT UNSIGNED NOT NULL,
  user_b_id INT UNSIGNED NOT NULL,
  FOREIGN KEY (user_a_id) REFERENCES users(id)
    ON DELETE CASCADE,
  FOREIGN KEY (user_b_id) REFERENCES users(id)
    ON DELETE CASCADE
);

CREATE INDEX idx_friendship_user_a_id ON friendship(user_a_id) COMMENT 'indexes the friendship table for better join performance on user_a_id';
CREATE INDEX idx_friendship_user_b_id ON friendship(user_b_id) COMMENT 'indexes the friendship table for better join performance on user_b_id';


-- Connections with Schools
-- A user should be able to create an affiliation with a given school.
-- And similarly, that school should be able to find its alumni.
-- Additionally, allow a user to define:
--
-- The start date of their affiliation (i.e., when they started to attend the school)
-- The end date of their affiliation (i.e., when they graduated), if applicable
-- The type of degree earned/pursued (e.g., “BA”, “MA”, “PhD”, etc.)
CREATE TABLE IF NOT EXISTS education (
  id             INT UNSIGNED PRIMARY KEY AUTO_INCREMENT,
  start_date     DATE         NOT NULL COMMENT 'a valid UTC date "YYYY-MM-DD"',
  end_date       DATE COMMENT 'an optional valid UTC date "YYYY-MM-DD"',
  degree_type    INT UNSIGNED COMMENT 'The type of degree earned/pursued (e.g., “BA”, “MA”, “PhD”, etc.)',
  user_id        INT UNSIGNED NOT NULL,
  institution_id INT UNSIGNED NOT NULL,
  FOREIGN KEY (degree_type) REFERENCES degree(id) ON DELETE SET NULL,
  FOREIGN KEY (user_id) REFERENCES users(id)
    ON DELETE CASCADE,
  FOREIGN KEY (institution_id) REFERENCES institutions(id)
    ON DELETE CASCADE
);



CREATE INDEX idx_education_user_id ON education(user_id) COMMENT 'enable the quick retrieval of educations for specific user_id';
CREATE INDEX idx_education_institution_id ON education(institution_id) COMMENT 'enable the quick retrieval of users for specific institution_id';
CREATE INDEX idx_education_degree_type ON education(degree_type) COMMENT 'enable the quick retrieval of users and institution by relation to degree_type';

-- Connections with Companies
-- A user should be able to create an affiliation with a given company.
-- And similarly, a company should be able to find its current and past employees.
-- Additionally, allow a user to define:
--
-- The start date of their affiliation (i.e., the date they began work with the company)
-- The end date of their affiliation (i.e., when left the company), if applicable
-- The title they held while affiliated with the company
CREATE TABLE IF NOT EXISTS employment (
  id         INT UNSIGNED PRIMARY KEY AUTO_INCREMENT,
  start_date DATE         NOT NULL COMMENT 'The start date of their affiliation (i.e., the date they began work with the company)',
  end_date   DATE COMMENT 'The optional end date of their affiliation (i.e., when left the company)',
  title      VARCHAR(50)  NOT NULL COMMENT 'The title they held while affiliated with the company',
  user_id    INT UNSIGNED NOT NULL,
  company_id INT UNSIGNED NOT NULL,
  FOREIGN KEY (user_id) REFERENCES users(id)
    ON DELETE CASCADE,
  FOREIGN KEY (company_id) REFERENCES companies(id)
    ON DELETE CASCADE
);

CREATE INDEX idx_employment_user_id ON employment(user_id) COMMENT 'index the employment for better join performance with user_id';
CREATE INDEX idx_employment_company_id ON employment(company_id) COMMENT 'index the employment for better join performance with company_id';
