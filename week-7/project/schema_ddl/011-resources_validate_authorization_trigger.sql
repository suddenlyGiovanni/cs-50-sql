SET search_path TO virtual_file_system, public;

CREATE OR REPLACE FUNCTION auth_create_trigger() RETURNS TRIGGER AS
$$
DECLARE
    _user_id        INTEGER := new.updated_by;
    _has_permission BOOLEAN := FALSE;
BEGIN
    /*
	 * Algorithm:
	 * 1. check for direct authorization to write permission on the parent_folder_id; if found allow the operation
	 * 2. traverse the parent chain recursively
	 *    - for each ancestor folder, check if the user has the required access rights
	 *    - if the user has the required access rights, allow the operation
	 * 3. stop the traversal when the parent_folder_id is NULL, indicating the top-level folder
	 * 4. if the traversal reaches the top-level folder and the user does not have the required access rights, deny the operation by raising an exception
	 */


    -- If parent_folder_id is NULL, indicating it is a top-level folder, skip the authorization check
    IF new.parent_folder_id IS NULL THEN
        RETURN new;
    END IF;

      WITH RECURSIVE resource_hierarchy AS (
          -- Base case: get the parent_folder_id of the current folder
          SELECT r_base.id
               , r_base.parent_folder_id
            FROM resources r_base
           WHERE r_base.id = new.parent_folder_id
           UNION ALL
-- Recursive case: add parent folders
          SELECT r.id
               , r.parent_folder_id
            FROM resources                    r
                INNER JOIN resource_hierarchy rh ON r.id = rh.parent_folder_id
                                           )
    SELECT exists (
        SELECT 1
          FROM resource_hierarchy                 rh
              JOIN user_role_resource_access_view urrav ON urrav.resource_id = rh.id
         WHERE urrav.user_id = _user_id
           AND urrav.write = TRUE
                  )
      INTO _has_permission;

    IF _has_permission THEN
        RETURN new;
    ELSE
        RAISE EXCEPTION 'User % does not have write permissions for this folder or any parent folders', _user_id;
    END IF;

END;
$$ LANGUAGE plpgsql;
COMMENT ON FUNCTION auth_create_trigger IS 'Trigger function to enforce authorization rules on the folders table';


CREATE OR REPLACE TRIGGER resources_validate_authorization_trigger
    BEFORE INSERT OR UPDATE
    ON resources
    FOR EACH ROW
EXECUTE FUNCTION auth_create_trigger();
