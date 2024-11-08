CREATE OR REPLACE FUNCTION validate_parent_folder_id() RETURNS TRIGGER AS
$$
BEGIN
    /*
    * A resource can be either a `folder` or a `file` type
    *
    * a valid `file` resource must have the parent_folder_ id:
    * - that must not be null
    * - must exist in the folder table
    *
    * a valid `folder` resource can either be a top level folder or a subfolder:
    * - a top-level folder must have a null parent_folder_id
    * - a subfolder must have a valid parent_folder_id that exists in the folder table
    */

    IF new.type = 'file' THEN
        IF new.parent_folder_id IS NULL THEN RAISE EXCEPTION 'A file resource must have a parent folder'; END IF;
        IF NOT exists(
                     SELECT 1
                       FROM folders
                      WHERE folders.id = new.parent_folder_id
                     ) THEN
            RAISE EXCEPTION 'Parent folder with id "%" does not exist', new.parent_folder_id;
        END IF;


    ELSIF new.type = 'folder' THEN
        IF new.parent_folder_id IS NOT NULL THEN
            IF NOT exists(
                         SELECT 1
                           FROM folders
                          WHERE folders.id = new.parent_folder_id
                         ) THEN
                RAISE EXCEPTION 'Parent folder with id "%" does not exist', new.parent_folder_id;
            END IF;
        END IF;
    END IF;

    RETURN new;
END;
$$ LANGUAGE plpgsql;
COMMENT ON FUNCTION validate_parent_folder_id IS 'Ensure that the parent folder exists for the folder being inserted or updated';

CREATE OR REPLACE TRIGGER validate_parent_folder_id_trigger
    BEFORE INSERT OR UPDATE OF parent_folder_id
    ON resources
    FOR EACH ROW
EXECUTE FUNCTION validate_parent_folder_id();
