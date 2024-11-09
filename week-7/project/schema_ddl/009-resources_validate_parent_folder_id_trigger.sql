CREATE OR REPLACE FUNCTION validate_parent_folder_exists(_parent_folder_id INTEGER) RETURNS BOOLEAN AS
$$
BEGIN
    RETURN exists(
                 SELECT 1
                   FROM virtual_file_system.public.resources r
                  WHERE _parent_folder_id = r.id AND r.type = 'folder'
                 );
END;
$$ LANGUAGE plpgsql;


CREATE OR REPLACE FUNCTION virtual_file_system.public.resources_validate_parent_folder_id() RETURNS TRIGGER AS
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
COMMENT ON FUNCTION virtual_file_system.public.resources_validate_parent_folder_id IS 'Ensure that the parent folder exists for the folder being inserted or updated';

CREATE OR REPLACE TRIGGER resources_validate_parent_folder_id_trigger
    BEFORE INSERT OR UPDATE OF parent_folder_id
    ON virtual_file_system.public.resources
    FOR EACH ROW
EXECUTE FUNCTION virtual_file_system.public.resources_validate_parent_folder_id();
