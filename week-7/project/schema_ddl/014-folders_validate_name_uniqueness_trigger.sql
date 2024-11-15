SET search_path TO virtual_file_system, public;

BEGIN;

CREATE OR REPLACE FUNCTION virtual_file_system.public.folders_validate_name_uniqueness() RETURNS TRIGGER
    LANGUAGE plpgsql AS
$$
DECLARE
    _resource_parent_id INTEGER;
BEGIN


    SELECT r.parent_folder_id
      INTO _resource_parent_id
      FROM virtual_file_system.public.resources AS r
     WHERE r.id = new.resource_id;

    IF _resource_parent_id IS NULL THEN -- Check for the same name at the top level
        IF exists(
            SELECT 1
              FROM virtual_file_system.public.folders       f
                  JOIN virtual_file_system.public.resources r ON f.resource_id = r.id
             WHERE r.parent_folder_id ISNULL
               AND f.name = new.name
                 ) THEN
            RAISE EXCEPTION 'Folder with name "%" already exists as a root resource', new.name;
        END IF;
    ELSE
        -- Check for the same name within the same parent folder

        IF exists(
            SELECT 1
              FROM virtual_file_system.public.resources   r_existing
                  JOIN virtual_file_system.public.folders f_existing ON f_existing.resource_id = r_existing.id
             WHERE r_existing.parent_folder_id = _resource_parent_id
               AND r_existing.type = 'folder'
               AND f_existing.name = new.name
                 ) THEN
            RAISE EXCEPTION 'Folder with name "%" already exists in the parent folder', new.name;
        END IF;
    END IF;
    RETURN new;
END;
$$;


CREATE OR REPLACE TRIGGER folders_validate_name_uniqueness_trigger
    BEFORE INSERT OR UPDATE
    ON folders
    FOR EACH ROW
EXECUTE FUNCTION virtual_file_system.public.folders_validate_name_uniqueness();

COMMIT;
