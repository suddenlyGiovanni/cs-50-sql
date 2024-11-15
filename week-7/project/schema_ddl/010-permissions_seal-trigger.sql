SET search_path TO virtual_file_system, public;

CREATE OR REPLACE FUNCTION permissions_seal() RETURNS TRIGGER AS
$$
BEGIN
    RAISE EXCEPTION 'Modifications to the permissions table are not allowed.';
    RETURN NULL;
END;
$$ LANGUAGE plpgsql;

DROP TRIGGER IF EXISTS permissions_seal_trigger ON permissions;
CREATE TRIGGER permissions_seal_trigger
    BEFORE INSERT OR UPDATE OR DELETE
    ON permissions
    FOR EACH ROW
EXECUTE FUNCTION permissions_seal();
COMMENT ON TRIGGER permissions_seal_trigger ON permissions IS 'Seal the permissions table';
