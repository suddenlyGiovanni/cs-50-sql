SET search_path TO virtual_file_system, public;

BEGIN;

CREATE OR REPLACE FUNCTION roles_seal() RETURNS TRIGGER AS
$$
BEGIN
    RAISE EXCEPTION 'Modifications to the roles table are not allowed.';
    RETURN NULL;
END;
$$ LANGUAGE plpgsql;

COMMIT;
