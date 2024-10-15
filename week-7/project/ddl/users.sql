DROP TABLE IF EXISTS users;
CREATE TABLE IF NOT EXISTS users (
    id              INTEGER PRIMARY KEY AUTOINCREMENT,
    username        TEXT     NOT NULL UNIQUE,                                                       -- unique username
    email           TEXT     NOT NULL UNIQUE,                                                       -- unique email
    hashed_password TEXT     NOT NULL,                                                              -- hashed password
    created_at      DATETIME NOT NULL                                    DEFAULT current_timestamp, -- READONLY User creation timestamp, auto-generated on creation
    deleted         INTEGER  NOT NULL CHECK ( deleted IN (TRUE, FALSE) ) DEFAULT FALSE              -- soft delete flag
);


DROP INDEX IF EXISTS users_username_index;
CREATE INDEX IF NOT EXISTS users_username_index ON users(username);

DROP INDEX IF EXISTS users_deleted_index;
CREATE INDEX IF NOT EXISTS users_deleted_index ON users(deleted);

DROP TRIGGER IF EXISTS users_prevent_created_at_update_trigger;
CREATE TRIGGER IF NOT EXISTS users_prevent_created_at_update_trigger
    BEFORE UPDATE
    ON users
    FOR EACH ROW
    WHEN new.created_at != old.created_at
BEGIN
    SELECT raise(ABORT, 'The created_at column is read-only and cannot be updated.');
END;

-- user soft delete trigger
DROP TRIGGER IF EXISTS users_soft_delete_trigger;
CREATE TRIGGER IF NOT EXISTS users_soft_delete_trigger
    BEFORE DELETE
    ON users
    FOR EACH ROW
BEGIN
    UPDATE users SET deleted = TRUE WHERE id = old.id;
    -- Prevent the deletion
    SELECT raise(IGNORE);
END;
