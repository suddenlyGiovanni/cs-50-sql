SET search_path TO virtual_file_system, public;

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

DROP TRIGGER IF EXISTS resources_updated_at_trigger ON resources;

CREATE TRIGGER resources_updated_at_trigger
    BEFORE INSERT OR UPDATE
    ON resources
    FOR EACH ROW
EXECUTE FUNCTION resource_update_timestamp();
