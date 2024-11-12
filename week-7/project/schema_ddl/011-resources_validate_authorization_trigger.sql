CREATE OR REPLACE FUNCTION virtual_file_system.public.auth_create_trigger() RETURNS TRIGGER AS
$$
DECLARE
    _user_id           INTEGER := new.updated_by;
    _current_folder_id INTEGER := new.parent_folder_id;
BEGIN
    /*
	 * Algorithm:
	 * 1. get the user_id from the reference to the resources table
	 * 2. check for direct authorization to write permission on the parent_folder_id; if found allow the operation
	 * 3. traverse the parent chain recursively
	 *    - for each ancestor folder, check if the user has the required access rights
	 *    - if the user has the required access rights, allow the operation
	 * 4. stop the traversal when the parent_folder_id is NULL, indicating the top-level folder
	 * 5. if the traversal reaches the top-level folder and the user does not have the required access rights, deny the operation by raising an exception
	 */


    -- if parent_folder_id is NULL, indicating it is a top-level folder, skip the authorization check
    IF _current_folder_id IS NULL THEN
        RETURN new;
    END IF;

    -- 1. check for direct authorization to write permission on the parent_folder_id; if found allow the operation

    WHILE _current_folder_id IS NOT NULL LOOP
        IF exists(
            SELECT 1
              FROM user_role_resource_access_view AS urrav
             WHERE urrav.resource_id = _current_folder_id
               AND urrav.user_id = _user_id
               AND urrav.write = TRUE
                 ) THEN
            -- if a valid write permission is found, allow the operation
            RETURN new;
        ELSE
            -- 2. traverse to the parent folder
            SELECT r.parent_folder_id
              INTO _current_folder_id
              FROM virtual_file_system.public.resources r
             WHERE r.id = _current_folder_id;
        END IF;
    END LOOP;

    -- 5. if the traversal reaches the top-level folder and the user does not have the required access rights, deny the operation by raising an exception
    RAISE EXCEPTION 'User "%" does not have write permissions for this folder or any parent folders', _user_id;

END;
$$ LANGUAGE plpgsql;
COMMENT ON FUNCTION virtual_file_system.public.auth_create_trigger IS 'Trigger function to enforce authorization rules on the folders table';


-- CREATE OR REPLACE TRIGGER auth_folder_create_trigger
--     BEFORE INSERT
--     ON virtual_file_system.public.resources
--     FOR EACH ROW
-- EXECUTE FUNCTION virtual_file_system.public.auth_create_trigger();
