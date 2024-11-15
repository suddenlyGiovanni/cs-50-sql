SET search_path TO virtual_file_system, public;

BEGIN;

CREATE OR REPLACE FUNCTION users_prevent_created_at_update() RETURNS TRIGGER AS
$$
BEGIN
    IF new.created_at != old.created_at THEN
        RAISE EXCEPTION 'The created_at column is read-only and cannot be updated.';
    END IF;
    RETURN new;
END;
$$ LANGUAGE plpgsql;

CREATE OR REPLACE FUNCTION users_soft_delete() RETURNS TRIGGER AS
$$
BEGIN
    UPDATE users SET deleted = TRUE WHERE id = old.id;
    -- prevent the deletion
    RETURN NULL;
END;
$$ LANGUAGE plpgsql;
COMMENT ON FUNCTION users_soft_delete() IS 'Soft delete function for users table';

DROP TRIGGER IF EXISTS users_prevent_created_at_update_trigger ON users;
CREATE TRIGGER users_prevent_created_at_update_trigger
    BEFORE UPDATE
    ON users
    FOR EACH ROW
EXECUTE FUNCTION users_prevent_created_at_update();

DROP TRIGGER IF EXISTS users_soft_delete_trigger ON users;
CREATE TRIGGER users_soft_delete_trigger
    BEFORE DELETE
    ON users
    FOR EACH ROW
EXECUTE FUNCTION users_soft_delete();

COMMENT ON TRIGGER users_soft_delete_trigger ON users IS 'Users soft delete trigger';

COMMIT;
