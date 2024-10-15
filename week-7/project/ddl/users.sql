DROP TABLE IF EXISTS users;
CREATE TABLE IF NOT EXISTS users (
    id              SERIAL PRIMARY KEY,
    username        VARCHAR(255) NOT NULL UNIQUE,
    email           VARCHAR(255) NOT NULL UNIQUE,
    hashed_password VARCHAR(255) NOT NULL,
    created_at      TIMESTAMP    NOT NULL DEFAULT current_timestamp,
    deleted         BOOLEAN      NOT NULL DEFAULT FALSE
);

COMMENT ON COLUMN users.id IS 'Unique user identifier';
COMMENT ON COLUMN users.username IS 'Unique username';
COMMENT ON COLUMN users.email IS 'Unique email';
COMMENT ON COLUMN users.hashed_password IS 'Hashed password';
COMMENT ON COLUMN users.created_at IS 'User creation timestamp, auto-generated on creation';
COMMENT ON COLUMN users.deleted IS 'Soft delete flag';



DROP INDEX IF EXISTS users_username_index;
CREATE INDEX IF NOT EXISTS users_username_index ON users(username);

DROP INDEX IF EXISTS users_deleted_index;
CREATE INDEX IF NOT EXISTS users_deleted_index ON users(deleted);


CREATE OR REPLACE FUNCTION prevent_created_at_update() RETURNS TRIGGER AS
$$
BEGIN
    IF new.created_at != old.created_at THEN
        RAISE EXCEPTION 'The created_at column is read-only and cannot be updated.';
    END IF;
    RETURN new;
END;
$$ LANGUAGE plpgsql;


DROP TRIGGER IF EXISTS users_prevent_created_at_update_trigger ON users;
CREATE TRIGGER users_prevent_created_at_update_trigger
    BEFORE UPDATE
    ON users
    FOR EACH ROW
EXECUTE FUNCTION prevent_created_at_update();


CREATE OR REPLACE FUNCTION users_soft_delete() RETURNS TRIGGER AS
$$
BEGIN
    UPDATE users SET deleted = TRUE WHERE id = old.id;
    -- prevent the deletion
    RETURN NULL;
END;
$$ LANGUAGE plpgsql;

DROP TRIGGER IF EXISTS users_soft_delete_trigger ON users;
CREATE TRIGGER users_soft_delete_trigger
    BEFORE DELETE
    ON users
    FOR EACH ROW
EXECUTE FUNCTION users_soft_delete();
COMMENT ON TRIGGER users_soft_delete_trigger ON users IS 'Users soft delete trigger';
