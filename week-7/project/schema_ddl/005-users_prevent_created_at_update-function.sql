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


COMMIT;
