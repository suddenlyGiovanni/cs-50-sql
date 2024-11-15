SET search_path TO virtual_file_system, public;


CREATE OR REPLACE FUNCTION permissions_seal() RETURNS TRIGGER AS
$$
BEGIN
    RAISE EXCEPTION 'Modifications to the permissions table are not allowed.';
    RETURN NULL;
END;
$$ LANGUAGE plpgsql;
