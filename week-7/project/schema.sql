-- In this SQL file, write (and comment!) the schema of your database, including the CREATE TABLE, CREATE INDEX, CREATE VIEW, etc. statements that compose it
DROP TABLE IF EXISTS users;
CREATE TABLE IF NOT EXISTS users (
    id         INTEGER PRIMARY KEY AUTOINCREMENT,
    username   TEXT    NOT NULL UNIQUE,
    email      TEXT    NOT NULL UNIQUE,
    password   TEXT    NOT NULL,
    role       TEXT    NOT NULL CHECK ( role IN ('user', 'admin', 'root') ) DEFAULT 'user',
    created_at TEXT    NOT NULL                                             DEFAULT current_timestamp,
    deleted    INTEGER NOT NULL CHECK ( deleted IN (TRUE, FALSE) )          DEFAULT FALSE
);

DROP INDEX IF EXISTS users_username_index;
CREATE INDEX IF NOT EXISTS users_username_index ON users(id, username);

DROP INDEX IF EXISTS users_role_index;
CREATE INDEX IF NOT EXISTS users_role_index ON users(id, role);


DROP VIEW IF EXISTS users_active;
CREATE VIEW IF NOT EXISTS users_active AS
SELECT id
     , username
     , email
     , password
     , role
     , created_at
  FROM users
 WHERE deleted = FALSE;


DROP TRIGGER IF EXISTS users_delete_trigger;
CREATE TRIGGER IF NOT EXISTS users_delete_trigger
    BEFORE DELETE
    ON users
    FOR EACH ROW
BEGIN
    UPDATE users SET deleted = TRUE WHERE id = old.id;
    -- Prevent the deletion
    SELECT raise(IGNORE);
END;
