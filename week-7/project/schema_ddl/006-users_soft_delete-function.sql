SET search_path TO virtual_file_system, public;

BEGIN;

CREATE OR REPLACE FUNCTION users_soft_delete() RETURNS TRIGGER AS
$$
BEGIN
    UPDATE users SET deleted = TRUE WHERE id = old.id;
    -- prevent the deletion
    RETURN NULL;
END;
$$ LANGUAGE plpgsql;

COMMENT ON FUNCTION users_soft_delete() IS 'Soft delete function for users table';

COMMIT;
