SET search_path TO virtual_file_system, public;

BEGIN;

CREATE OR REPLACE FUNCTION virtual_file_system.public.files_validate_name_uniqueness() RETURNS TRIGGER
    LANGUAGE plpgsql AS
$$
DECLARE
    _resource_parent_id INTEGER;
BEGIN


    SELECT r.parent_folder_id
      INTO _resource_parent_id
      FROM virtual_file_system.public.resources AS r
     WHERE r.id = new.resource_id;


    -- Check for the same name within the same parent folder

    IF exists(
        SELECT 1
          FROM virtual_file_system.public.resources r_existing
              JOIN virtual_file_system.public.files f_existing ON f_existing.resource_id = r_existing.id
         WHERE r_existing.parent_folder_id = _resource_parent_id
           AND r_existing.type = 'file'
           AND f_existing.name = new.name
             ) THEN
        RAISE EXCEPTION 'File with name "%" already exists in the parent folder id "%"', new.name,_resource_parent_id;
    END IF;
    RETURN new;
END;
$$;


CREATE OR REPLACE TRIGGER files_validate_name_uniqueness_trigger
    BEFORE INSERT OR UPDATE
    ON files
    FOR EACH ROW
EXECUTE FUNCTION virtual_file_system.public.files_validate_name_uniqueness();

COMMIT;
