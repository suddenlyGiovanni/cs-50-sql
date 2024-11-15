SET search_path TO virtual_file_system, public;

BEGIN;
CREATE OR REPLACE FUNCTION resource_update_timestamp() RETURNS TRIGGER AS
$$
BEGIN
    IF (tg_op = 'INSERT') THEN
        new.updated_at := new.created_at;
    ELSEIF (tg_op = 'UPDATE') THEN
        new.updated_at := current_timestamp;
    END IF;
    RETURN new;
END;
$$ LANGUAGE plpgsql;
COMMENT ON FUNCTION resource_update_timestamp() IS 'Function to update the updated_at timestamp on every insert or update operation on the resources table';

COMMIT;
