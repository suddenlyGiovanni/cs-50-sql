SET search_path TO virtual_file_system, public;

BEGIN;
CREATE OR REPLACE FUNCTION validate_parent_folder_exists(_parent_folder_id INTEGER) RETURNS BOOLEAN AS
$$
BEGIN
    RETURN exists(
        SELECT 1 FROM resources r WHERE _parent_folder_id = r.id AND r.type = 'folder'
                 );
END;
$$ LANGUAGE plpgsql;


CREATE OR REPLACE FUNCTION resources_validate_parent_folder_id() RETURNS TRIGGER AS
$$
BEGIN
    IF new.type = 'file' THEN
        IF new.parent_folder_id IS NULL THEN
            RAISE EXCEPTION 'A file resource must have a parent folder';
        ELSIF NOT validate_parent_folder_exists(new.parent_folder_id) THEN
            RAISE EXCEPTION 'Parent folder with id "%" does not exist', new.parent_folder_id;
        END IF;


    ELSIF new.type = 'folder' AND new.parent_folder_id IS NOT NULL THEN
        IF NOT validate_parent_folder_exists(new.parent_folder_id) THEN
            RAISE EXCEPTION 'Parent folder with id "%" does not exist', new.parent_folder_id;
        END IF;
    END IF;

    RETURN new;
END;
$$ LANGUAGE plpgsql;
COMMENT ON FUNCTION resources_validate_parent_folder_id IS 'Ensure that the parent folder exists for the folder being inserted or updated';


COMMIT;
